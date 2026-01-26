import { AbilityConstant, ConfigurationConstant, UIAbility, Want, abilityAccessCtrl } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { worker, ErrorEvent, MessageEvents } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import vibrator from '@ohos.vibrator';
import { HTTPPollService } from '../service/HTTPPollService';
import { RecommendationData } from '../service/DataService';
import { CommonConstants } from '../common/CommonConstants';

const DOMAIN = 0x0000;

interface WorkerMessage {
  type: 'recommendationData' | 'error' | 'workerError' | 'refresh_needed';
  data?: RecommendationData;
  error?: string;
}

interface WorkerCommand {
  command?: 'start' | 'stop' | 'config' | 'restart';
}



let httpPollService: HTTPPollService | null = null;
let pollWorker: worker.ThreadWorker | null = null;

export default class EntryAbility extends UIAbility {
  private backgroundTaskId: number = -1;
  private lastRestartTime: number = 0;
  private readonly RESTART_COOLDOWN: number = 110000; // 110秒冷却（2分钟定时任务间隔）

  private async startBackgroundTask(): Promise<void> {
    try {
      // 创建WantAgent（通知栏点击跳转）
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [{
          bundleName: "com.example.myapplication",
          abilityName: "EntryAbility"
        }],
        actionType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0,
        wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
      };

      const wantAgentObj: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);

      // 申请长时任务
      await backgroundTaskManager.startBackgroundRunning(
        this.context,
        backgroundTaskManager.BackgroundMode.DATA_TRANSFER,
        wantAgentObj
      );

      hilog.info(DOMAIN, 'EntryAbility', '长时任务申请成功');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EntryAbility', '长时任务申请失败: %{public}s', JSON.stringify(err));
    }
  }

  private stopBackgroundTask(): void {
    try {
      backgroundTaskManager.stopBackgroundRunning(this.context);
      hilog.info(DOMAIN, 'EntryAbility', '长时任务已停止');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EntryAbility', '停止长时任务失败: %{public}s', JSON.stringify(err));
    }
  }

  private async refreshBackgroundTask(): Promise<void> {
    // 防抖检查
    const now = Date.now();
    if (now - this.lastRestartTime < this.RESTART_COOLDOWN) {
      hilog.info(DOMAIN, 'EntryAbility', '冷却中，跳过重启');
      return;
    }

    this.lastRestartTime = now;
    hilog.info(DOMAIN, 'EntryAbility', '开始刷新后台任务');

    // 1. 停止当前后台任务
    this.stopBackgroundTask();

    // 2. 重启Worker轮询
    if (pollWorker) {
      pollWorker.postMessage({ command: 'restart' } as WorkerCommand);
    }

    // 3. 重新申请后台任务
    await this.startBackgroundTask();

    hilog.info(DOMAIN, 'EntryAbility', '后台任务刷新完成');
  }

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onCreate');

    // 创建HTTP轮询服务实例（用于数据处理）
    httpPollService = new HTTPPollService(this.context, CommonConstants.SERVER_URL);

    // 请求震动权限
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      await atManager.requestPermissionsFromUser(this.context, ['ohos.permission.VIBRATE']);
      hilog.info(DOMAIN, 'EntryAbility', 'Vibrate permission granted or already had');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to request vibrate permission: %{public}s', JSON.stringify(err));
    }

    // 启动长时后台任务
    await this.startBackgroundTask();

    // 创建Worker进行后台HTTP轮询
    try {
      pollWorker = new worker.ThreadWorker('entry/ets/workers/HTTPPollWorker.ets');

      // 注册消息回调
      pollWorker.onmessage = (e: MessageEvents) => {
        const message = e.data as WorkerMessage;
        switch (message.type) {
          case 'recommendationData':
            if (message.data && httpPollService) {
              // 处理推荐数据
              httpPollService.saveToPreferences(message.data).then(() => {
                hilog.info(DOMAIN, 'EntryAbility', 'Data processed by worker successfully');
              }).catch((error: BusinessError) => {
                hilog.error(DOMAIN, 'EntryAbility', 'Failed to process data: %{public}s', JSON.stringify(error));
              });
            }
            break;

          case 'refresh_needed':
            hilog.info(DOMAIN, 'EntryAbility', '收到Worker刷新通知，触发后台任务刷新');
            this.refreshBackgroundTask();
            break;

          case 'error':
          case 'workerError':
            hilog.error(DOMAIN, 'EntryAbility', 'Worker error: %{public}s', message.error);
            break;
        }
      };

      // 注册错误回调
      pollWorker.onAllErrors = (err: ErrorEvent) => {
        hilog.error(DOMAIN, 'EntryAbility', 'Worker onAllErrors: %{public}s', JSON.stringify(err));
      };

      // 注册退出回调
      pollWorker.onexit = (code: number) => {
        hilog.info(DOMAIN, 'EntryAbility', 'Worker exited with code: %{public}d', code);
      };

      // 启动Worker轮询
      pollWorker.postMessage({ command: 'start' } as WorkerCommand);
      hilog.info(DOMAIN, 'EntryAbility', 'Worker started for HTTP polling');
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'EntryAbility', 'Failed to create worker: %{public}s', JSON.stringify(err));
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'EntryAbility', 'Ability onDestroy');

    // 停止长时任务
    this.stopBackgroundTask();

    // 终止Worker
    if (pollWorker) {
      try {
        pollWorker.terminate();
        hilog.info(DOMAIN, 'EntryAbility', 'Worker terminated');
      } catch (error) {
        const err = error as BusinessError;
        hilog.error(DOMAIN, 'EntryAbility', 'Failed to terminate worker: %{public}s', JSON.stringify(err));
      }
      pollWorker = null;
    }

    if (httpPollService) {
      httpPollService.stopPolling();
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err: BusinessError) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    hilog.info(DOMAIN, 'EntryAbility', '应用回到前台，刷新后台任务');
    this.refreshBackgroundTask();
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}