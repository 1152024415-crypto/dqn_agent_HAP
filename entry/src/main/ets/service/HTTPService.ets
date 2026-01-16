import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { fs } from '@kit.CoreFileKit';

const DOMAIN = 0x0000;

/**
 * HTTP服务类 - 提供JSON上传API
 */
export class HTTPService {
  private tcpServer: socket.TCPSocketServer | null = null;
  private isRunning: boolean = false;
  private context: common.UIAbilityContext | null = null;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

  /**
   * 启动HTTP服务器
   */
  startServer(): void {
    if (this.isRunning) {
      hilog.warn(DOMAIN, 'HTTPService', 'Server already running');
      return;
    }

    try {
      hilog.info(DOMAIN, 'HTTPService', 'Starting HTTP server on 0.0.0.0:8080');

      this.tcpServer = socket.constructTCPSocketServerInstance();

      const listenAddr: socket.NetAddress = {
        address: '0.0.0.0',
        port: 8080,
        family: 1
      };

      this.tcpServer.listen(listenAddr, (err: BusinessError) => {
        if (err) {
          hilog.error(DOMAIN, 'HTTPService', 'Listen failed: %{public}s', JSON.stringify(err));
          this.isRunning = false;
        } else {
          hilog.info(DOMAIN, 'HTTPService', 'Server started successfully');
          this.isRunning = true;
        }
      });

      this.tcpServer.on('connect', (clientSocket: socket.TCPSocketConnection) => {
        hilog.info(DOMAIN, 'HTTPService', 'New client connected');

        clientSocket.on('message', (msgInfo: socket.SocketMessageInfo) => {
          try {
            const requestString = this.arrayBufferToString(msgInfo.message);
            hilog.info(DOMAIN, 'HTTPService', 'Received request: %{public}s', requestString.substring(0, 200));

            const response = this.handleRequest(requestString);
            clientSocket.send({ data: response });

            hilog.info(DOMAIN, 'HTTPService', 'Response sent');
          } catch (error) {
            hilog.error(DOMAIN, 'HTTPService', 'Error handling request: %{public}s', JSON.stringify(error));
          }
        });
      });

    } catch (error) {
      hilog.error(DOMAIN, 'HTTPService', 'Failed to start server: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 停止HTTP服务器
   */
  stopServer(): void {
    if (this.tcpServer) {
      try {
        this.tcpServer.off('connect');
        hilog.info(DOMAIN, 'HTTPService', 'Server stopped');
      } catch (error) {
        hilog.error(DOMAIN, 'HTTPService', 'Error stopping server: %{public}s', JSON.stringify(error));
      }

      this.tcpServer = null;
      this.isRunning = false;
    }
  }

  /**
   * 处理HTTP请求
   */
  private handleRequest(request: string): string {
    try {
      // 解析HTTP请求
      const lines = request.split('\r\n');
      if (lines.length === 0) {
        return this.buildResponse(400, 'Bad Request');
      }

      // 提取请求行
      const requestLine = lines[0];
      hilog.info(DOMAIN, 'HTTPService', 'Request line: %{public}s', requestLine);

      // 解析POST /jsonUpload
      const parts = requestLine.split(' ');
      if (parts.length < 2) {
        return this.buildResponse(400, 'Bad Request');
      }

      const method = parts[0];
      const path = parts[1];

      if (method !== 'POST') {
        hilog.warn(DOMAIN, 'HTTPService', 'Unsupported method: %{public}s', method);
        return this.buildResponse(405, 'Method Not Allowed');
      }

      if (path !== '/jsonUpload') {
        hilog.warn(DOMAIN, 'HTTPService', 'Not found: %{public}s', path);
        return this.buildResponse(404, 'Not Found');
      }

      // 提取body（JSON数据）
      const body = this.extractBody(request);
      if (!body) {
        hilog.warn(DOMAIN, 'HTTPService', 'Empty body');
        return this.buildResponse(400, 'Bad Request - Empty body');
      }

      hilog.info(DOMAIN, 'HTTPService', 'Received JSON: %{public}s', body);

      // 解析JSON数据
      const data = DataService.parseRecommendationData(body);

      if (data) {
        // 写入文件
        this.writeDataToFile(body);
        hilog.info(DOMAIN, 'HTTPService', 'Data written to file, Widget will read and update');
        return this.buildResponse(200, 'OK');
      } else {
        hilog.error(DOMAIN, 'HTTPService', 'Invalid JSON data');
        return this.buildResponse(400, 'Bad Request - Invalid JSON');
      }

    } catch (error) {
      hilog.error(DOMAIN, 'HTTPService', 'Error processing request: %{public}s', JSON.stringify(error));
      return this.buildResponse(500, 'Internal Server Error');
    }
  }

  /**
   * 提取HTTP请求body
   */
  private extractBody(request: string): string | null {
    // 找到空行（headers和body的分隔符）
    const emptyLineIndex = request.indexOf('\r\n\r\n');
    if (emptyLineIndex === -1) {
      return null;
    }

    return request.substring(emptyLineIndex + 4);
  }

  /**
   * 写入数据到文件
   */
  private writeDataToFile(jsonString: string): void {
    if (!this.context) {
      hilog.error(DOMAIN, 'HTTPService', 'Context is null, cannot write to file');
      return;
    }

    try {
      const filesDir = this.context.filesDir;
      const filePath = `${filesDir}/latest_recommendation.json`;

      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.TRUNC | fs.OpenMode.WRITE_ONLY);
      const textEncoder = new util.TextEncoder();
      const writeBuffer = textEncoder.encodeInto(jsonString);
      fs.writeSync(file.fd, writeBuffer);
      fs.closeSync(file);

      hilog.info(DOMAIN, 'HTTPService', 'Data written to: %{public}s', filePath);
    } catch (error) {
      hilog.error(DOMAIN, 'HTTPService', 'Failed to write to file: %{public}s', JSON.stringify(error));
    }
  }

  /**
   * 构建HTTP响应
   */
  private buildResponse(statusCode: number, message: string): string {
    const statusText = this.getStatusText(statusCode);
    const body = message;

    let response = `HTTP/1.1 ${statusCode} ${statusText}\r\n`;
    response += 'Content-Type: text/plain; charset=utf-8\r\n';
    response += `Content-Length: ${body.length}\r\n`;
    response += '\r\n';
    response += body;

    return response;
  }

  /**
   * 获取HTTP状态码文本
   */
  private getStatusText(statusCode: number): string {
    const statusMap: Record<number, string> = {
      200: 'OK',
      400: 'Bad Request',
      404: 'Not Found',
      405: 'Method Not Allowed',
      500: 'Internal Server Error'
    };
    return statusMap[statusCode] || 'Unknown';
  }

  /**
   * ArrayBuffer转字符串
   */
  private arrayBufferToString(buffer: ArrayBuffer): string {
    const msgArray = new Uint8Array(buffer);
    const textDecoder = util.TextDecoder.create('utf-8');
    return textDecoder.decodeWithStream(msgArray);
  }

  /**
   * 检查服务器是否运行
   */
  isServerRunning(): boolean {
    return this.isRunning;
  }
}
