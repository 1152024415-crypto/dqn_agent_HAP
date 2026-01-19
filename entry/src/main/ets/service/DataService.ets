import { hilog } from '@kit.PerformanceAnalysisKit';
import { ActionData } from '../common/CommonData';

const DOMAIN = 0x0000;

/**
 * Recommendation data interface (new unified format)
 */
export interface RecommendationData {
  id: string;
  timestamp: number;
  action_type: 'probe' | 'recommend' | 'none';
  action_name: string;
  image: string | null;  // base64 encoded image or null
  scene_category: string;
}

/**
 * JSON data interface for parsing
 */
interface JsonData {
  id?: string;
  timestamp?: number;
  action_type?: string;
  action_name?: string;
  image?: string | null;
  scene_category?: string;
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
      if (!data.id || !data.timestamp || !data.action_type || !data.action_name || !data.scene_category) {
        hilog.warn(DOMAIN, 'DataServiceHAP', 'Missing required fields in data');
        return null;
      }

      // Validate action_type field
      if (data.action_type !== 'probe' && data.action_type !== 'recommend' && data.action_type !== 'none') {
        hilog.warn(DOMAIN, 'DataServiceHAP', 'Invalid action_type: %{public}s', data.action_type);
        return null;
      }

      // Validate action_name field
      if (!DataService.isValidAction(data.action_name)) {
        hilog.warn(DOMAIN, 'DataServiceHAP', 'Invalid action_name: %{public}s', data.action_name);
        // Continue anyway, as action names may evolve
      }

      // image can be null or string
      const image = data.image === undefined ? null : data.image;

      return {
        id: data.id,
        timestamp: data.timestamp,
        action_type: data.action_type as 'probe' | 'recommend' | 'none',
        action_name: data.action_name,
        image: image,
        scene_category: data.scene_category
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
   * Get action type label text
   */
  static getActionTypeLabel(actionType: string): string {
    switch (actionType) {
      case 'probe':
        return '[Probe]';
      case 'recommend':
        return '[Recommend]';
      case 'none':
        return '[None]';
      default:
        return '[Unknown]';
    }
  }

  /**
   * Get action type label background color
   */
  static getActionTypeLabelBgColor(actionType: string): string {
    switch (actionType) {
      case 'probe':
        return '#E6F7FF';  // light blue for probe
      case 'recommend':
        return '#E8F5E9';  // light green for recommend
      case 'none':
        return '#E0E0E0';  // gray for none
      default:
        return '#E0E0E0';
    }
  }

  /**
   * Get action type label text color
   */
  static getActionTypeLabelTextColor(actionType: string): string {
    switch (actionType) {
      case 'probe':
        return '#1890FF';  // blue for probe
      case 'recommend':
        return '#52C41A';  // green for recommend
      case 'none':
        return '#666666';  // dark gray for none
      default:
        return '#666666';
    }
  }
}
