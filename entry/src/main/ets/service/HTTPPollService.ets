import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { CommonConstants } from '../common/CommonConstants';
import { DataService, RecommendationData } from './DataService';
import { common } from '@kit.AbilityKit';
import { formBindingData, formProvider, formInfo } from '@kit.FormKit';
import { FormCardData, FormData, ActionData } from '../common/CommonData';
import vibrator from '@ohos.vibrator';

const DOMAIN = 0x0000;

export class HTTPPollService {
  private serverUrl: string = '';
  private isPolling: boolean = false;
  private pollInterval: number = 2000; // 2秒轮询一次
  private pollTimer: number = -1;
  private context: common.Context;

  constructor(context: common.Context, serverUrl: string = CommonConstants.SERVER_URL) {
    this.context = context;
    this.serverUrl = serverUrl;
  }

  setServerUrl(url: string): void {
    this.serverUrl = url;
    hilog.info(DOMAIN, 'HTTPPollService', 'Server URL updated: %{public}s', this.serverUrl);
  }

  startPolling(): void {
    if (this.isPolling) {
      hilog.warn(DOMAIN, 'HTTPPollService', 'Already polling');
      return;
    }

    hilog.info(DOMAIN, 'HTTPPollService', 'Starting polling to: %{public}s', this.serverUrl);
    this.isPolling = true;

    // 立即执行一次
    this.pollData();

    // 设置定时轮询
    this.pollTimer = setInterval(() => {
      this.pollData();
    }, this.pollInterval);
  }

  stopPolling(): void {
    if (!this.isPolling) {
      return;
    }

    hilog.info(DOMAIN, 'HTTPPollService', 'Stopping polling');
    this.isPolling = false;

    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
  }

  private async pollData(): Promise<void> {
    if (!this.serverUrl) {
      hilog.error(DOMAIN, 'HTTPPollService', 'Server URL is empty');
      return;
    }

    try {
      const url = `${this.serverUrl}/latest-recommendation`;
      hilog.info(DOMAIN, 'HTTPPollService', 'Polling: %{public}s', url);

      const httpRequest = http.createHttp();
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 5000,
        readTimeout: 5000,
        header: {
          'Content-Type': 'application/json'
        }
      });

      if (response.responseCode === 200) {
        const result = response.result as string;
        hilog.info(DOMAIN, 'HTTPPollService', 'Received data: %{public}s', result.substring(0, 200));

        const data = DataService.parseRecommendationData(result);
        if (data) {
          await this.saveToPreferences(data);
          hilog.info(DOMAIN, 'HTTPPollService', 'Data saved to Preferences');
        } else {
          hilog.warn(DOMAIN, 'HTTPPollService', 'Invalid data format');
        }
      } else if (response.responseCode === 204) {
        // No Content - 服务器暂无数据
        hilog.info(DOMAIN, 'HTTPPollService', 'No new data available (204)');
      } else {
        hilog.error(DOMAIN, 'HTTPPollService', 'HTTP error: %{public}d', response.responseCode);
      }

      httpRequest.destroy();
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'HTTPPollService', 'Polling failed: %{public}s', JSON.stringify(err));
    }
  }

   private async triggerVibration(duration: number = 800): Promise<void> {
    try {
      await vibrator.startVibration({
        type: 'time',
        duration: duration
      }, {
        usage: 'notification'
      });
      
      hilog.info(DOMAIN, 'HTTPPollService', 'Vibration triggered: %{public}dms', duration);
    } catch (error) {
      const err = error as BusinessError;
      hilog.error(DOMAIN, 'HTTPPollService', 'Vibration failed: code=%{public}d, message=%{public}s', 
        err?.code || -1, err?.message || JSON.stringify(error));
    }
  }

   private shouldTriggerVibration(newData: RecommendationData): boolean {
    try {
      const util = PreferencesUtil.getInstance();
      const preferences = util.getPreferences(this.context);
      if (!preferences) {
        hilog.warn(DOMAIN, 'HTTPPollService', 'No preferences available, will vibrate');
        return true;
      }

      // Get last saved data
      const lastDataJson = util.preferencesGet(preferences, CommonConstants.LAST_DATA_KEY, '{}') as string;
      if (lastDataJson === '{}') {
        hilog.info(DOMAIN, 'HTTPPollService', 'First time data, will vibrate');
        // Save current data for next comparison
        util.preferencesPut(preferences, CommonConstants.LAST_DATA_KEY, JSON.stringify(newData));
        return true;
      }

      let lastData: RecommendationData;
      try {
        lastData = JSON.parse(lastDataJson) as RecommendationData;
      } catch (parseError) {
        hilog.error(DOMAIN, 'HTTPPollService', 'Failed to parse last data JSON, will vibrate: %{public}s', JSON.stringify(parseError));
        // Save current data for next comparison
        util.preferencesPut(preferences, CommonConstants.LAST_DATA_KEY, JSON.stringify(newData));
        return true;
      }
      
      // Compare key fields (excluding id and timestamp)
      const lastImage = lastData.image || null;
      const newImage = newData.image || null;
      const dataChanged = 
        lastData.action_type !== newData.action_type ||
        lastData.action_name !== newData.action_name ||
        lastData.scene_category !== newData.scene_category ||
        lastImage !== newImage;
      
      hilog.info(DOMAIN, 'HTTPPollService', 'Data comparison - changed: %{public}s, action_type: %{public}s vs %{public}s, action_name: %{public}s vs %{public}s, scene: %{public}s vs %{public}s, image: %{public}s vs %{public}s',
        dataChanged ? 'true' : 'false',
        lastData.action_type, newData.action_type,
        lastData.action_name, newData.action_name,
        lastData.scene_category, newData.scene_category,
        lastImage ? 'has_image' : 'null', newImage ? 'has_image' : 'null');
      
      // Save current data for next comparison
      util.preferencesPut(preferences, CommonConstants.LAST_DATA_KEY, JSON.stringify(newData));
      
      return dataChanged;
    } catch (error) {
      hilog.error(DOMAIN, 'HTTPPollService', 'Vibration check failed: %{public}s', JSON.stringify(error));
      return true;  // On error, vibrate (conservative approach)
    }
  }

   public async saveToPreferences(data: RecommendationData): Promise<void> {
    try {
      const util = PreferencesUtil.getInstance();
      const preferences = util.getPreferences(this.context);

      if (preferences) {
        const jsonString = JSON.stringify(data);
        util.preferencesPut(preferences, CommonConstants.DATA_KEY, jsonString);
        hilog.info(DOMAIN, 'HTTPPollService', 'Saved to Preferences: %{public}s', jsonString.substring(0, 200));

         // Trigger vibration only if data changed (excluding id and timestamp)
        if (this.shouldTriggerVibration(data)) {
          await this.triggerVibration(800);
        }

        // 获取所有formId并更新所有Widget
        const formIds = util.getAllFormIds(preferences);
        
        if (formIds.length === 0) {
          // 兼容旧版本：获取单个formId
          const singleFormId = util.preferencesGet(preferences, CommonConstants.FORM_ID_KEY, '') as string;
          if (singleFormId) {
            formIds.push(singleFormId);
          }
        }
        
        if (formIds.length > 0) {
          hilog.info(DOMAIN, 'HTTPPollService', 'Updating %{public}d forms: %{public}s', formIds.length, JSON.stringify(formIds));
          
           // Convert data format to FormData
          const actionData: ActionData = {
            action_type: data.action_type,
            action_name: data.action_name,
            image: data.image,
            scene_category: data.scene_category
          };

          const formCardData = new FormCardData();
          formCardData.id = data.id;
          formCardData.timestamp = data.timestamp;
          formCardData.action_data = actionData;
          formCardData.favour = false;

          hilog.info(DOMAIN, 'HTTPPollService', 'FormCardData - id: %{public}s, action: %{public}s, type: %{public}s', 
            formCardData.id, formCardData.action_data.action_name, formCardData.action_data.action_type);
          
          // 为每个formId更新卡片
          for (const formId of formIds) {
            try {
              const formData = new FormData();
              formData.formId = formId;
              formData.formTime = Date.now().toString();
              formData.cardList = [formCardData];

              hilog.info(DOMAIN, 'HTTPPollService', 'FormData - formId: %{public}s, formTime: %{public}s, cardList length: %{public}d', formData.formId, formData.formTime, formData.cardList.length);

              const formMsg = formBindingData.createFormBindingData(formData);
              await formProvider.updateForm(formId, formMsg);
              hilog.info(DOMAIN, 'HTTPPollService', 'Form updated successfully: %{public}s', formId);
            } catch (error) {
              hilog.error(DOMAIN, 'HTTPPollService', 'Failed to update form %{public}s: %{public}s', formId, JSON.stringify(error));
            }
          }
        } else {
          hilog.warn(DOMAIN, 'HTTPPollService', 'No formId found in Preferences');
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, 'HTTPPollService', 'Failed to save or update form: %{public}s', JSON.stringify(error));
    }
  }

  isRunning(): boolean {
    return this.isPolling;
  }
}
