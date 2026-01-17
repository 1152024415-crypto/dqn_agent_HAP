import { hilog } from '@kit.PerformanceAnalysisKit';
import { RuleEngineData, DQNData, VLMData } from '../common/CommonData';

const DOMAIN = 0x0000;

/**
 * Recommendation data interface (new format)
 */
export interface RecommendationData {
  id: string;
  timestamp: number;
  active_module: 'rule_engine' | 'dqn' | 'vlm';

  rule_engine?: RuleEngineData;
  dqn?: DQNData;
  vlm?: VLMData;
}

/**
 * JSON data interface for parsing
 */
interface JsonData {
  id?: string;
  timestamp?: number;
  active_module?: string;
  rule_engine?: RuleEngineData;
  dqn?: DQNData;
  vlm?: VLMData;
}

/**
 * Data processing service - handles WebSocket data parsing
 */
export class DataService {
  /**
   * Parse JSON string to RecommendationData object
   */
  static parseRecommendationData(jsonString: string): RecommendationData | null {
    try {
      const data: JsonData = JSON.parse(jsonString);

      // Validate required fields
      if (!data.id || !data.timestamp || !data.active_module) {
        hilog.warn(DOMAIN, 'DataServiceHAP', 'Missing required fields in data');
        return null;
      }

      // Validate active_module field
      if (data.active_module !== 'rule_engine' &&
          data.active_module !== 'dqn' &&
          data.active_module !== 'vlm') {
        hilog.warn(DOMAIN, 'DataServiceHAP', 'Invalid active_module: %{public}s', data.active_module);
        return null;
      }

      // Validate module data based on active_module
      if (data.active_module === 'rule_engine' && !data.rule_engine) {
        hilog.warn(DOMAIN, 'DataServiceHAP', 'Missing rule_engine data');
        return null;
      }

      if (data.active_module === 'dqn' && !data.dqn) {
        hilog.warn(DOMAIN, 'DataServiceHAP', 'Missing dqn data');
        return null;
      }

      if (data.active_module === 'vlm' && (!data.dqn || !data.vlm)) {
        hilog.warn(DOMAIN, 'DataServiceHAP', 'Missing dqn or vlm data for vlm module');
        return null;
      }

      return {
        id: data.id,
        timestamp: data.timestamp,
        active_module: data.active_module as 'rule_engine' | 'dqn' | 'vlm',
        rule_engine: data.rule_engine,
        dqn: data.dqn,
        vlm: data.vlm
      };

    } catch (error) {
      hilog.error(DOMAIN, 'DataServiceHAP', 'JSON parse error - %{public}s', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Format timestamp to relative time string
   */
  static formatTime(timestamp: number): string {
    const now = Date.now();
    const diff = now - timestamp * 1000; // Convert to milliseconds

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
   * Validate action field
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
   * Get module label text
   */
  static getModuleLabel(activeModule: string): string {
    switch (activeModule) {
      case 'rule_engine':
        return '[Rule]';
      case 'dqn':
        return '[DQN]';
      case 'vlm':
        return '[VLM]';
      default:
        return '[Unknown]';
    }
  }

  /**
   * Get module label background color
   */
  static getModuleLabelBgColor(activeModule: string): string {
    switch (activeModule) {
      case 'rule_engine':
        return '#E0E0E0';
      case 'dqn':
        return '#E6F7FF';
      case 'vlm':
        return '#F9F0FF';
      default:
        return '#E0E0E0';
    }
  }

  /**
   * Get module label text color
   */
  static getModuleLabelTextColor(activeModule: string): string {
    switch (activeModule) {
      case 'rule_engine':
        return '#666666';
      case 'dqn':
        return '#1890FF';
      case 'vlm':
        return '#722ED1';
      default:
        return '#666666';
    }
  }
}
