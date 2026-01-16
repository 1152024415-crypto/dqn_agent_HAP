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
    if (this.ws) {
      hilog.warn(DOMAIN, 'WebSocketService', 'WebSocket already connected');
      return;
    }

    this.updateStatus(ConnectionStatus.CONNECTING);

    try {
      this.ws = webSocket.createWebSocket();

      this.ws.on('open', () => {
        hilog.info(DOMAIN, 'WebSocketService', 'WebSocket connected to ${public}', this.serverUrl);
        this.reconnectAttempts = 0;
        this.updateStatus(ConnectionStatus.CONNECTED);
      });

      this.ws.on('message', (err: BusinessError<void>, value: string | ArrayBuffer) => {
        if (typeof value === 'string' && this.messageCallback) {
          hilog.info(DOMAIN, 'WebSocketService', 'Received message: ${public}', value);
          this.messageCallback(value);
        }
      });

      this.ws.on('close', () => {
        hilog.info(DOMAIN, 'WebSocketService', 'WebSocket closed');
        this.updateStatus(ConnectionStatus.DISCONNECTED);
        this.ws = null;
        
        // 自动重连
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
          this.scheduleReconnect();
        }
      });

      this.ws.on('error', (err: Error) => {
        hilog.error(DOMAIN, 'WebSocketService', 'WebSocket error: ${public}', JSON.stringify(err));
        this.updateStatus(ConnectionStatus.ERROR);
        this.ws = null;
      });

      this.ws.connect(this.serverUrl);
      
    } catch (error) {
      hilog.error(DOMAIN, 'WebSocketService', 'Connection error: ${public}', JSON.stringify(error));
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
        console.log('WebSocketService: Disconnected');
      } catch (error) {
        console.error(`WebSocketService: Disconnect error - ${JSON.stringify(error)}`);
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

    console.log(`WebSocketService: Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts})`);

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