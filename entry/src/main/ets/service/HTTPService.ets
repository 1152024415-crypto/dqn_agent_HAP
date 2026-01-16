import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DataService, RecommendationData } from './DataService';
import { common } from '@kit.AbilityKit';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { CommonConstants } from '../common/CommonConstants';

const DOMAIN = 0x0000;

export class HTTPService {
  private tcpServer: socket.TCPSocketServer | null = null;
  private isRunning: boolean = false;
  private context: common.UIAbilityContext | null = null;

  constructor(context: common.UIAbilityContext) {
    this.context = context;
  }

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

  private handleRequest(request: string): string {
    try {
      const lines = request.split('\r\n');
      if (lines.length === 0) {
        return this.buildResponse(400, 'Bad Request');
      }

      const requestLine = lines[0];
      hilog.info(DOMAIN, 'HTTPService', 'Request line: %{public}s', requestLine);

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

      const body = this.extractBody(request);
      if (!body) {
        hilog.warn(DOMAIN, 'HTTPService', 'Empty body');
        return this.buildResponse(400, 'Bad Request - Empty body');
      }

      hilog.info(DOMAIN, 'HTTPService', 'Received JSON: %{public}s', body);

      const data = DataService.parseRecommendationData(body);

      if (data) {
        this.saveToPreferences(data);
        hilog.info(DOMAIN, 'HTTPService', 'Data saved to Preferences');
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

  private extractBody(request: string): string | null {
    const emptyLineIndex = request.indexOf('\r\n\r\n');
    if (emptyLineIndex === -1) {
      return null;
    }

    return request.substring(emptyLineIndex + 4);
  }

  private saveToPreferences(data: RecommendationData): void {
    if (!this.context) {
      hilog.error(DOMAIN, 'HTTPService', 'Context is null, cannot save to Preferences');
      return;
    }

    try {
      const util = PreferencesUtil.getInstance();
      const preferences = util.getPreferences(this.context);

      if (preferences) {
        const jsonString = JSON.stringify(data);
        util.preferencesPut(preferences, CommonConstants.DATA_KEY, jsonString);
      }
    } catch (error) {
      hilog.error(DOMAIN, 'HTTPService', 'Failed to save to Preferences: %{public}s', JSON.stringify(error));
    }
  }

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

  private arrayBufferToString(buffer: ArrayBuffer): string {
    const msgArray = new Uint8Array(buffer);
    const textDecoder = util.TextDecoder.create('utf-8');
    return textDecoder.decodeWithStream(msgArray);
  }

  isServerRunning(): boolean {
    return this.isRunning;
  }
}
