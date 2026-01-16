import { preferences } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG: string = 'PreferencesUtil';
const MY_STORE: string = 'recommendationStore';

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

  preferencesGet(preferences: preferences.Preferences, key: string, defaultValue: string): any {
    try {
      if (preferences.hasSync(key)) {
        return preferences.getSync(key, defaultValue);
      }
      return defaultValue;
    } catch (error) {
      let err = error as BusinessError;
      hilog.error(DOMAIN, TAG, `preferencesGet failed, error code=${err.code}, message=${err.message}`);
      return defaultValue;
    }
  }
}
