import vibrator from '@ohos.vibrator';

/**
 * Simple vibration service - triggers vibration based on action type
 */
export class SimpleVibrationService {
  private static vibratorId: number = 0;

  /**
   * Vibrate based on action type
   * - Recommend action: short vibration (300ms)
   * - Probe action: long vibration (800ms)
   */
  static vibrateByActionType(actionType: string): void {
    const duration = actionType === 'recommend' ? 300 : 800;

    try {
      vibrator.startVibration({
        type: 'time',
        duration: duration
      }, {
        id: SimpleVibrationService.vibratorId,
        usage: 'notification'
      });

      console.log(`SimpleVibrationService: Vibrated ${duration}ms for action type: ${actionType}`);
    } catch (error) {
      console.error(`SimpleVibrationService: Vibration error - ${JSON.stringify(error)}`);
    }
  }

  /**
   * Stop any ongoing vibration
   */
  static stopVibration(): void {
    try {
      vibrator.stopVibration({
        id: SimpleVibrationService.vibratorId
      });
      console.log('SimpleVibrationService: Vibration stopped');
    } catch (error) {
      console.error(`SimpleVibrationService: Stop error - ${JSON.stringify(error)}`);
    }
  }
}