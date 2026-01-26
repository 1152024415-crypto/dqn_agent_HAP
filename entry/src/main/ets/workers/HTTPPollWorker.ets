import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { worker, ThreadWorkerGlobalScope, MessageEvents, ErrorEvent } from '@kit.ArkTS';
import { DataService, RecommendationData } from '../service/DataService';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CommonConstants } from '../common/CommonConstants';

const workerPort: ThreadWorkerGlobalScope = worker.workerPort;
const DOMAIN = 0x0000;

interface WorkerCommand {
  command?: 'start' | 'stop' | 'config' | 'restart';
}

interface WorkerResponse {
  type: 'recommendationData' | 'error' | 'workerError' | 'refresh_needed';
  data?: RecommendationData;
  error?: string;
}

// 配置
const POLL_INTERVAL = 2000; // 2秒
const REFRESH_THRESHOLD = 120000; // 2分钟（毫秒）
const POLL_CHECK_INTERVAL = 30; // 每30次轮询检查一次（约1分钟）

let pollingTimer: number | null = null;
let isPolling = false;
let startTime: number = 0;
let pollCount: number = 0;

// 处理主线程消息
workerPort.onmessage = (e: MessageEvents) => {
  const data = e.data as WorkerCommand;
  const command = data.command;

  switch (command) {
    case 'start':
      startPolling();
      break;
    case 'stop':
      stopPolling();
      break;
    case 'restart':
      stopPolling();
      startPolling();
      break;
    case 'config':
      // 可以接收配置，这里简化
      break;
    default:
    // 默认开始轮询
      startPolling();
  }
};

// 启动轮询
function startPolling(): void {
  if (isPolling) {
    return;
  }

  isPolling = true;
  startTime = Date.now();
  pollCount = 0;

  // 立即执行一次
  pollData();

  // 设置定时轮询
  pollingTimer = setInterval(() => {
    pollData();
  }, POLL_INTERVAL);
}

// 停止轮询
function stopPolling(): void {
  if (!isPolling) {
    return;
  }

  isPolling = false;

  if (pollingTimer !== null) {
    clearInterval(pollingTimer);
    pollingTimer = null;
  }
}

// 轮询数据
async function pollData(): Promise<void> {
  // 计时检查：每POLL_CHECK_INTERVAL次轮询检查一次时间
  pollCount++;
  if (pollCount % POLL_CHECK_INTERVAL === 0) {
    const elapsed = Date.now() - startTime;
    if (elapsed >= REFRESH_THRESHOLD) {
      // 发送刷新通知给主线程
      workerPort.postMessage({ type: 'refresh_needed' });
      hilog.info(DOMAIN, 'HTTPPollWorker', 'Worker运行%{public}dms，通知Ability刷新后台任务', elapsed);

      // 重置计时器
      startTime = Date.now();
      pollCount = 0;
    }
  }
  try {
    const url = `${CommonConstants.SERVER_URL}/latest-recommendation`;

    const httpRequest = http.createHttp();
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 5000,
      readTimeout: 5000,
      header: {
        'Content-Type': 'application/json'
      }
    });

    if (response.responseCode === 200) {
      const result = response.result as string;

      const data = DataService.parseRecommendationData(result);
      if (data) {
        // 发送数据给主线程
        const responseMessage: WorkerResponse = {
          type: 'recommendationData',
          data: data
        };
        workerPort.postMessage(responseMessage);
      }
    } else if (response.responseCode === 204) {
      // No Content - 服务器暂无数据
    }

    httpRequest.destroy();
  } catch (error) {
    const err = error as BusinessError;
    // 可以发送错误信息给主线程
    const errorMessage: WorkerResponse = {
      type: 'error',
      error: err.message
    };
    workerPort.postMessage(errorMessage);
  }
}

// 处理错误
workerPort.onerror = (err: ErrorEvent) => {
  // 错误处理
  try {
    workerPort.postMessage({
      type: 'workerError',
      error: err.message
    });
  } catch (error) {
    // TODO: Implement error handling.
    hilog.error(DOMAIN, 'HttpPollWorker', 'postMessage err');
  }
};