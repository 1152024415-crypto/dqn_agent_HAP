/**
 * 元数据接口
 */
export interface ActionMetadata {
  reward: number;
  description: string;
}

/**
 * 动作数据接口
 */
export interface ActionData {
  id: string;
  type: 'recommend' | 'probe';
  action: string;
  timestamp: number;
  metadata: ActionMetadata;
}

/**
 * JSON数据接口（用于解析）
 */
interface JsonData {
  id?: string;
  type?: string;
  action?: string;
  timestamp?: number;
  metadata?: ActionMetadata;
}

/**
 * 数据处理服务 - 处理接收到的WebSocket数据
 */
export class DataService {
  /**
   * 解析JSON字符串为ActionData对象
   */
  static parseActionData(jsonString: string): ActionData | null {
    try {
      const data: JsonData = JSON.parse(jsonString);

      // 验证必要字段
      if (!data.id || !data.type || !data.action || !data.metadata) {
        console.warn('DataService: Missing required fields in data');
        return null;
      }

      // 验证type字段
      if (data.type !== 'recommend' && data.type !== 'probe') {
        console.warn(`DataService: Invalid type: ${data.type}`);
        return null;
      }

      // 验证metadata字段
      if (!data.metadata.reward || !data.metadata.description) {
        console.warn('DataService: Missing metadata fields');
        return null;
      }

      // 构建ActionData对象
      return {
        id: data.id,
        type: data.type,
        action: data.action,
        timestamp: data.timestamp,
        metadata: data.metadata
      };

    } catch (error) {
      console.error(`DataService: JSON parse error - ${JSON.stringify(error)}`);
      return null;
    }
  }

  /**
   * 格式化时间戳为相对时间字符串
   */
  static formatTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp * 1000; // 转换为毫秒

    const seconds = Math.floor(diff / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const days = Math.floor(hours / 24);

    if (seconds < 60) {
      return 'just now';
    } else if (minutes < 60) {
      return `${minutes}m ago`;
    } else if (hours < 24) {
      return `${hours}h ago`;
    } else {
      return `${days}d ago`;
    }
  }

  /**
   * 验证action字段是否有效
   */
  static isValidAction(action: string): boolean {
    const validActions = [
      'QUERY_LOC_NET', 'QUERY_LOC_GPS', 'QUERY_VISUAL', 
      'QUERY_SOUND_INTENSITY', 'QUERY_LIGHT_INTENSITY',
      'NONE', 'step_count_and_map', 'transit_QR_code',
      'train_information', 'flight_information', 'payment_QR_code',
      'preferred_APP', 'glasses_snapshot', 'identify_person',
      'silent_DND', 'navigation', 'audio_record',
      'relax', 'arrived', 'parking'
    ];

    return validActions.includes(action);
  }

  /**
   * 格式化reward值
   */
  static formatReward(reward: number): string {
    return reward.toFixed(2);
  }
}