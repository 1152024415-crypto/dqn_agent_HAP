import vibrator from '@ohos.vibrator';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@kit.BaseKit';
import { common } from '@kit.AbilityKit';

/**
 * 震动模式枚举
 */
export enum VibrationMode {
  RECOMMEND = 'recommend',
  PROBE = 'probe',
  CONNECTED = 'connected',
  ERROR = 'error'
}

/**
 * 震动服务类 - 管理设备震动功能
 */
export class VibrationService {
  private static vibratorId: number = 0;
  private static hasPermission: boolean = false;

  /**
   * 检查震动权限状态
   */
  static async checkPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenId = context.applicationInfo.accessTokenId;
      const permission = 'ohos.permission.VIBRATE';

      const grantStatus = await atManager.checkAccessToken(tokenId, permission);
      this.hasPermission = grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

      console.log(`VibrationService: Permission check - ${this.hasPermission}`);
      return this.hasPermission;

    } catch (error) {
      console.error(`VibrationService: Check permission error - ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 申请震动权限
   */
  static async requestPermission(context: common.UIAbilityContext): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const permissions = ['ohos.permission.VIBRATE'];

      const result = await atManager.requestPermissionsFromUser(context, permissions);
      
      // 检查权限是否授予
      for (let i = 0; i < result.authResults.length; i++) {
        if (result.authResults[i] === 0) {
          this.hasPermission = true;
        }
      }

      console.log(`VibrationService: Permission request result - ${this.hasPermission}`);
      return this.hasPermission;

    } catch (error) {
      console.error(`VibrationService: Request permission error - ${JSON.stringify(error)}`);
      return false;
    }
  }

  /**
   * 确保有震动权限
   */
  static async ensurePermission(context: common.UIAbilityContext): Promise<void> {
    if (!this.hasPermission) {
      const granted = await this.checkPermission(context);
      if (!granted) {
        console.log('VibrationService: Requesting vibration permission');
        await this.requestPermission(context);
      }
    }
  }

  /**
   * 触发推荐动作震动（短震动）
   */
  static vibrateRecommend(): void {
    if (!this.hasPermission) {
      console.warn('VibrationService: No vibration permission');
      return;
    }

    try {
      vibrator.startVibration({
        type: 'time',
        duration: 500
      }, {
        id: this.vibratorId,
        usage: 'notification'
      });

      console.log('VibrationService: Recommend vibration triggered (500ms)');
    } catch (error) {
      console.error(`VibrationService: Vibrate recommend error - ${JSON.stringify(error)}`);
    }
  }

  /**
   * 触发探测动作震动（长震动）
   */
  static vibrateProbe(): void {
    if (!this.hasPermission) {
      console.warn('VibrationService: No vibration permission');
      return;
    }

    try {
      vibrator.startVibration({
        type: 'time',
        duration: 1000
      }, {
        id: this.vibratorId,
        usage: 'notification'
      });

      console.log('VibrationService: Probe vibration triggered (1000ms)');
    } catch (error) {
      console.error(`VibrationService: Vibrate probe error - ${JSON.stringify(error)}`);
    }
  }

  /**
   * 触发连接成功震动（非常短的震动）
   */
  static vibrateConnected(): void {
    if (!this.hasPermission) {
      return;
    }

    try {
      vibrator.startVibration({
        type: 'time',
        duration: 200
      }, {
        id: this.vibratorId,
        usage: 'notification'
      });

      console.log('VibrationService: Connected vibration triggered (200ms)');
    } catch (error) {
      console.error(`VibrationService: Vibrate connected error - ${JSON.stringify(error)}`);
    }
  }

  /**
   * 触发连接错误震动（双震动）
   */
  static vibrateError(): void {
    if (!this.hasPermission) {
      return;
    }

    try {
      // 双震动模式：震动-停止-震动
      vibrator.startVibration({
        type: 'time',
        duration: 300
      }, {
        id: this.vibratorId,
        usage: 'notification'
      });

      console.log('VibrationService: Error vibration triggered (300ms)');
    } catch (error) {
      console.error(`VibrationService: Vibrate error error - ${JSON.stringify(error)}`);
    }
  }

  /**
   * 根据模式触发震动
   */
  static async vibrate(mode: VibrationMode): Promise<void> {
    if (!this.hasPermission) {
      console.warn(`VibrationService: Cannot vibrate, no permission. Mode: ${mode}`);
      return;
    }

    console.log(`VibrationService: Triggering vibration mode: ${mode}`);

    switch (mode) {
      case VibrationMode.RECOMMEND:
        this.vibrateRecommend();
        break;
      case VibrationMode.PROBE:
        this.vibrateProbe();
        break;
      case VibrationMode.CONNECTED:
        this.vibrateConnected();
        break;
      case VibrationMode.ERROR:
        this.vibrateError();
        break;
      default:
        console.warn(`VibrationService: Unknown vibration mode: ${mode}`);
    }
  }

  /**
   * 停止震动
   */
  static stopVibration(): void {
    try {
      vibrator.stopVibration({
        id: this.vibratorId
      });
      console.log('VibrationService: Vibration stopped');
    } catch (error) {
      console.error(`VibrationService: Stop vibration error - ${JSON.stringify(error)}`);
    }
  }

  /**
   * 设置权限状态
   */
  static setPermissionGranted(granted: boolean): void {
    this.hasPermission = granted;
    console.log(`VibrationService: Permission status set to ${granted}`);
  }
}