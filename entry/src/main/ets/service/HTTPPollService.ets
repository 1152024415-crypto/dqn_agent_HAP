import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { CommonConstants } from '../common/CommonConstants';
import { DataService, RecommendationData } from './DataService';
import { common } from '@kit.AbilityKit';
import { formBindingData, formProvider, formInfo } from '@kit.FormKit';
import { FormCardData, FormData } from '../common/CommonData';
import { RuleEngineData, DQNData, VLMData } from '../common/CommonData';

const DOMAIN = 0x0000;

export class HTTPPollService {
  private serverUrl: string = '';
  private isPolling: boolean = false;
  private pollInterval: number = 2000; // 2秒轮询一次
  private pollTimer: number = -1;
  private context: common.UIAbilityContext | null = null;

  constructor(context: common.UIAbilityContext, serverUrl: string = 'http://127.0.0.1:8080') {
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

   public async saveToPreferences(data: RecommendationData): Promise<void> {
    if (!this.context) {
      hilog.error(DOMAIN, 'HTTPPollService', 'Context is null');
      return;
    }

    try {
      const util = PreferencesUtil.getInstance();
      const preferences = util.getPreferences(this.context);

      if (preferences) {
        const jsonString = JSON.stringify(data);
        util.preferencesPut(preferences, CommonConstants.DATA_KEY, jsonString);
        hilog.info(DOMAIN, 'HTTPPollService', 'Saved to Preferences: %{public}s', jsonString.substring(0, 200));

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
          
          // 转换数据格式为FormData
          const formCardData = new FormCardData();
          formCardData.id = data.id;
          formCardData.timestamp = data.timestamp;
          formCardData.active_module = data.active_module;
          formCardData.rule_engine = data.rule_engine;
          formCardData.dqn = data.dqn;
          formCardData.vlm = data.vlm;
          formCardData.favour = false;

          hilog.info(DOMAIN, 'HTTPPollService', 'FormCardData - id: %{public}s, module: %{public}s', formCardData.id, formCardData.active_module);
          
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
