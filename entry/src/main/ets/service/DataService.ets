import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

/**
 * 动作数据接口
 */
export interface ActionData {
  id: string;
  type: 'recommend' | 'probe';
  action: string;
  timestamp: number;
  metadata: {
    reward: number;
    description: string;
  };
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
      const data = JSON.parse(jsonString);
      
      // 验证必要字段
      if (!data.id || !data.type || !data.action || !data.metadata) {
        hilog.warn(DOMAIN, 'DataService', 'Missing required fields in data');
        return null;
      }

      // 验证type字段
      if (data.type !== 'recommend' && data.type !== 'probe') {
        hilog.warn(DOMAIN, 'DataService', 'Invalid type: %{public}s', data.type);
        return null;
      }

      // 验证metadata字段
      if (!data.metadata.reward || !data.metadata.description) {
        hilog.warn(DOMAIN, 'DataService', 'Missing metadata fields');
        return null;
      }

      // 验证reward范围
      if (typeof data.metadata.reward !== 'number' || data.metadata.reward < 0 || data.metadata.reward > 1) {
        hilog.warn(DOMAIN, 'DataService', 'Invalid reward value: %{public}s', data.metadata.reward);
        return null;
      }

      return data as ActionData;

    } catch (error) {
      hilog.error(DOMAIN, 'DataService', 'JSON parse error: %{public}s', JSON.stringify(error));
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