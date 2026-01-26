import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { Context } from '@kit.AbilityKit';
import { CommonConstants } from '../CommonConstants';

const DOMAIN = 0x0000;
const TAG: string = 'PreferencesUtil';
const MY_STORE: string = 'recommendationStore';  // Fixed spelling

export class PreferencesUtil {
  private static preferencesUtil: PreferencesUtil | null = null;

  public static getInstance(): PreferencesUtil {
    if (!PreferencesUtil.preferencesUtil) {
      PreferencesUtil.preferencesUtil = new PreferencesUtil();
    }
    return PreferencesUtil.preferencesUtil;
  }

  getPreferences(context: Context): preferences.Preferences | undefined {
    try {
      preferences.removePreferencesFromCacheSync(context, MY_STORE);
      return preferences.getPreferencesSync(context, { name: MY_STORE });
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `getPreferences failed, error code=${err.code}, message=${err.message}`);
      return undefined;
    }
  }

  preferencesFlush(preferences: preferences.Preferences) {
    preferences.flush((err) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `Failed to flush. Code:${err.code}, message:${err.message}`);
      }
    })
  }

  preferencesPut(preferences: preferences.Preferences, key: string, value: preferences.ValueType): void {
    try {
      preferences.putSync(key, value);
      this.preferencesFlush(preferences);
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `preferencesPut failed, error code=${err.code}, message=${err.message}`);
    }
  }

  preferencesGet(preferences: preferences.Preferences, key: string, defaultValue: string): string {
    try {
      if (preferences.hasSync(key)) {
        return preferences.getSync(key, defaultValue) as string;
      }
      return defaultValue;
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `preferencesGet failed, error code=${err.code}, message=${err.message}`);
      return defaultValue;
    }
  }

  // 添加formId到列表
  addFormId(preferences: preferences.Preferences, formId: string): void {
    try {
      let formIdsJson = this.preferencesGet(preferences, CommonConstants.FORM_IDS_KEY, '[]');
      let formIds: string[] = JSON.parse(formIdsJson);

      if (!formIds.includes(formId)) {
        formIds.push(formId);
        this.preferencesPut(preferences, CommonConstants.FORM_IDS_KEY, JSON.stringify(formIds));
        hilog.info(DOMAIN, TAG, `Added formId to list: ${formId}, total: ${formIds.length}`);
      }
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `addFormId failed, error code=${err.code}, message=${err.message}`);
    }
  }

  // 获取所有formId列表
  getAllFormIds(preferences: preferences.Preferences): string[] {
    try {
      let formIdsJson = this.preferencesGet(preferences, CommonConstants.FORM_IDS_KEY, '[]');
      return JSON.parse(formIdsJson);
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `getAllFormIds failed, error code=${err.code}, message=${err.message}`);
      return [];
    }
  }
}
