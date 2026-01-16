import vibrator from '@ohos.vibrator';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

/**
 * Vibration level enumeration
 */
export enum VibrationLevel {
  RULE_ENGINE = 200,
  DQN_RECOMMEND = 300,
  DQN_PROBE = 800,
  VLM = 1500
}

/**
 * Vibration service - triggers vibration based on active module and action type
 */
export class VibrationService {
  /**
   * Vibrate based on active module and action type
   * - Rule Engine: 200ms short vibration
   * - DQN Recommend: 300ms vibration
   * - DQN Probe: 800ms long vibration
   * - VLM: 1500ms double vibration
   */
  static vibrateByModule(activeModule: string, actionType?: string): void {
    try {
      if (activeModule === 'rule_engine') {
        VibrationService.singleVibration(VibrationLevel.RULE_ENGINE, 'rule_engine');
      } else if (activeModule === 'dqn') {
        if (actionType === 'recommend') {
          VibrationService.singleVibration(VibrationLevel.DQN_RECOMMEND, 'dqn_recommend');
        } else if (actionType === 'probe') {
          VibrationService.singleVibration(VibrationLevel.DQN_PROBE, 'dqn_probe');
        }
      } else if (activeModule === 'vlm') {
        VibrationService.doubleVibration();
      }
    } catch (error) {
      hilog.error(DOMAIN, 'VibrationService', 'Vibration error - %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Single vibration
   */
  private static singleVibration(duration: number, label: string): void {
    try {
      vibrator.startVibration({
        type: 'time',
        duration: duration
      }, {
        usage: 'notification'
      });

      hilog.info(DOMAIN, 'VibrationService', 'Single vibration %{public}dms for %{public}s', duration, label);
    } catch (error) {
      hilog.error(DOMAIN, 'VibrationService', 'Single vibration error - %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Double vibration for VLM
   */
  private static doubleVibration(): void {
    try {
      vibrator.startVibration({
        type: 'preset',
        effectId: 'haptic.clock.timer',
        count: 2
      }, {
        usage: 'notification'
      });

      hilog.info(DOMAIN, 'VibrationService', 'Double vibration for VLM');
    } catch (error) {
      hilog.error(DOMAIN, 'VibrationService', 'Double vibration error - %{public}s', JSON.stringify(error));
    }
  }

  /**
   * Stop any ongoing vibration
   */
  static stopVibration(): void {
    try {
      vibrator.stopVibration();
      hilog.info(DOMAIN, 'VibrationService', 'Vibration stopped');
    } catch (error) {
      hilog.error(DOMAIN, 'VibrationService', 'Stop error - %{public}s', JSON.stringify(error));
    }
  }
}
