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
const TAG: string = 'HTTPPollService';
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
           // 调试日志：记录接收到的dqn_state数据
           if (data.dqn_state) {
             hilog.info(DOMAIN, 'HTTPPollService', 'Received dqn_state: activity=%{public}s, location=%{public}s, light=%{public}s, scene=%{public}s',
               data.dqn_state.activity, data.dqn_state.location, data.dqn_state.light, data.dqn_state.scene);
           } else {
             hilog.warn(DOMAIN, 'HTTPPollService', 'dqn_state is undefined in parsed data!');
           }
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
        hilog.info(DOMAIN, TAG, `[Step 1] Saved new data to Prefs. (Action: ${data.action_name})`);

        if (this.shouldTriggerVibration(data)) {
          await this.triggerVibration(800);
        }

        // === [核心修正] 强化卡片更新通知逻辑 ===

        // 1. 获取所有当前存在的卡片ID
        const allFormIds = util.getAllFormIds(preferences);

        if (allFormIds.length > 0) {
          hilog.info(DOMAIN, TAG, `[Step 2] Found ${allFormIds.length} forms to update: ${JSON.stringify(allFormIds)}`);

           // 2. 将新数据转换为卡片需要的数据结构
           // (这部分逻辑最好放在这里，而不是在 onUpdateForm 中，以确保数据一致性)
           // 调试日志：记录actionData中的dqn_state值
           hilog.info(DOMAIN, TAG, `[DEBUG] Creating actionData, dqn_state exists: ${data.dqn_state ? 'YES' : 'NO'}`);
           if (data.dqn_state) {
             hilog.info(DOMAIN, TAG, `[DEBUG] dqn_state values: activity=${data.dqn_state.activity}, location=${data.dqn_state.location}, light=${data.dqn_state.light}, scene=${data.dqn_state.scene}`);
           }
           
           const actionData: ActionData = {
             action_type: data.action_type,
             action_name: data.action_name,
             image: data.image,
             scene_category: data.scene_category,
              // 确保dqn_state始终有值，即使data.dqn_state为undefined
              dqn_state: data.dqn_state || {
                activity: '--',
                location: '--',
                light: '--',
                scene: '--'
              }
           };

          const formCardData = new FormCardData();
          formCardData.id = data.id;
          formCardData.timestamp = data.timestamp;
          formCardData.action_data = actionData;

          // 3. 遍历并更新每一个卡片实例
          const updatePromises = allFormIds.map(formId => {
            try {
              const formData = new FormData();
              formData.formId = formId; // 确保每个卡片拿到的数据里有自己的ID
              formData.formTime = Date.now().toString();
              formData.cardList = [formCardData];

              const formMsg = formBindingData.createFormBindingData(formData);

              hilog.info(DOMAIN, TAG, `[Step 3] Sending update signal to form: ${formId}`);

              // 发起更新
              return formProvider.updateForm(formId, formMsg)
                .then(() => {
                  hilog.info(DOMAIN, TAG, `[SUCCESS] updateForm for ${formId} successful.`);
                })
                .catch((error: BusinessError) => {
                  hilog.error(DOMAIN, TAG, `[FAIL] updateForm for ${formId} failed: ${JSON.stringify(error)}`);
                });
            } catch (innerError) {
              hilog.error(DOMAIN, TAG, `[CRITICAL] Error preparing update for form ${formId}: ${JSON.stringify(innerError)}`);
              return Promise.resolve(); // 避免一个卡片的错误中断所有
            }
          });

          await Promise.all(updatePromises);
          hilog.info(DOMAIN, TAG, `[Step 4] All form update attempts finished.`);

        } else {
          hilog.warn(DOMAIN, TAG, 'No formIds found in Preferences. Card will not update.');
        }
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to save or update form: %{public}s', JSON.stringify(error));
    }
  }


  isRunning(): boolean {
    return this.isPolling;
  }
}
