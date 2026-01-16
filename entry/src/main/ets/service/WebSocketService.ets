import { webSocket } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

/**
 * WebSocket连接状态枚举
 */
export enum ConnectionStatus {
  DISCONNECTED = 'disconnected',
  CONNECTING = 'connecting',
  CONNECTED = 'connected',
  ERROR = 'error'
}

/**
 * WebSocket服务类 - 管理与服务器的WebSocket连接
 */
export class WebSocketService {
  private ws: webSocket.WebSocket | null = null;
  private serverUrl: string;
  private messageCallback: ((data: string) => void) | null = null;
  private statusCallback: ((status: ConnectionStatus) => void) | null = null;
  private reconnectTimer: number = -1;
  private reconnectAttempts: number = 0;
  private maxReconnectAttempts: number = 5;

  constructor(serverUrl: string = 'ws://0.0.0.0:8080/recommendation-stream') {
    this.serverUrl = serverUrl;
  }

  /**
   * 连接到WebSocket服务器
   */
  connect(): void {
    hilog.info(DOMAIN, 'WebSocketServiceHAP', 'try connect');
    if (this.ws) {
      hilog.warn(DOMAIN, 'WebSocketServiceHAP', 'Already connected');
      return;
    }

    this.updateStatus(ConnectionStatus.CONNECTING);

    try {
      hilog.info(DOMAIN, 'WebSocketServiceHAP', 'webSocket creating');
      if (this.ws == null) {
        this.ws = webSocket.createWebSocket();
      }
      hilog.info(DOMAIN, 'WebSocketServiceHAP', 'webSocket created, connecting to %{public}s', this.serverUrl);

      this.ws.on('open', () => {
        hilog.info(DOMAIN, 'WebSocketServiceHAP', 'Connected to %{public}s', this.serverUrl);
        this.reconnectAttempts = 0;
        this.updateStatus(ConnectionStatus.CONNECTED);
      });

      this.ws.on('message', (err: BusinessError<void>, value: string | ArrayBuffer) => {
        if (typeof value === 'string' && this.messageCallback) {
          hilog.info(DOMAIN, 'WebSocketServiceHAP', 'Received message: %{public}s', value);
          this.messageCallback(value);
        }
      });

      this.ws.on('close', () => {
        hilog.info(DOMAIN, 'WebSocketServiceHAP', 'Closed');
        this.updateStatus(ConnectionStatus.DISCONNECTED);
        this.ws = null;

        // 自动重连
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
          this.scheduleReconnect();
        }
      });

      this.ws.on('error', (err: Error) => {
        hilog.error(DOMAIN, 'WebSocketServiceHAP', 'Error - %{public}s', JSON.stringify(err));
        this.updateStatus(ConnectionStatus.ERROR);
        this.ws = null;
      });

      this.ws.connect(this.serverUrl, (err: BusinessError, value: boolean) => {
        if (!err) {
          hilog.info(DOMAIN, 'WebSocketServiceHAP', "connect success")
        } else {
          hilog.error(DOMAIN, 'WebSocketServiceHAP', `connect fail. Code: ${err.code}, message: ${err.message}`)
        }
      });

    } catch (error) {
      hilog.error(DOMAIN, 'WebSocketServiceHAP', 'Connection error - %{public}s', JSON.stringify(error));
      this.updateStatus(ConnectionStatus.ERROR);
    }
  }

  /**
   * 断开WebSocket连接
   */
  disconnect(): void {
    if (this.reconnectTimer !== -1) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = -1;
    }

    if (this.ws) {
      try {
        this.ws.close();
        this.ws = null;
        hilog.info(DOMAIN, 'WebSocketServiceHAP', 'Disconnected');
      } catch (error) {
        hilog.error(DOMAIN, 'WebSocketServiceHAP', 'Disconnect error - %{public}s', JSON.stringify(error));
      }
    }

    this.reconnectAttempts = 0;
    this.updateStatus(ConnectionStatus.DISCONNECTED);
  }

  /**
   * 安排重连
   */
  private scheduleReconnect(): void {
    this.reconnectAttempts++;
    const delay = Math.min(1000 * Math.pow(2, this.reconnectAttempts - 1), 30000);

    hilog.info(DOMAIN, 'WebSocketServiceHAP', 'Reconnecting in %{public}dms (attempt %{public}d/%{public}d)', delay, this.reconnectAttempts, this.maxReconnectAttempts);

    this.reconnectTimer = setTimeout(() => {
      this.connect();
    }, delay);
  }

  /**
   * 设置消息回调
   */
  onMessage(callback: (data: string) => void): void {
    this.messageCallback = callback;
  }

  /**
   * 设置状态回调
   */
  onStatusChange(callback: (status: ConnectionStatus) => void): void {
    this.statusCallback = callback;
  }

  /**
   * 更新连接状态
   */
  private updateStatus(status: ConnectionStatus): void {
    if (this.statusCallback) {
      this.statusCallback(status);
    }
  }

  /**
   * 获取当前连接状态
   */
  getStatus(): ConnectionStatus {
    if (!this.ws) {
      return ConnectionStatus.DISCONNECTED;
    }
    // WebSocket没有直接的API获取状态，我们通过回调跟踪状态
    return ConnectionStatus.DISCONNECTED;
  }

  /**
   * 检查是否已连接
   */
  isConnected(): boolean {
    return this.ws !== null;
  }
}