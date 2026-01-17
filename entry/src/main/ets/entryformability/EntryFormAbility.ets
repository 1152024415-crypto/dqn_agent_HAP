import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { FormData, FormCardData, RuleEngineData, DQNData, VLMData } from '../common/CommonData';
import { CommonConstants } from '../common/CommonConstants';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryFormAbility';

// Interface for parsed JSON data
interface JsonData {
  id?: string;
  timestamp?: number;
  active_module?: string;
  rule_engine?: RuleEngineData;
  dqn?: DQNData;
  vlm?: VLMData;
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    if (!want || !want.parameters) {
      return formBindingData.createFormBindingData('');
    }
    let formId: string = want.parameters[formInfo.FormParam.IDENTITY_KEY] as string;

    try {
      let util = PreferencesUtil.getInstance();
      let preferences = util.getPreferences(this.context);
      if (preferences) {
        // 保存当前formId（供单个卡片更新使用）
        util.preferencesPut(preferences, CommonConstants.FORM_ID_KEY, formId);
        // 添加到formId列表（供批量更新使用）
        util.addFormId(preferences, formId);
        hilog.info(0x0000, TAG, `Saved formId to Preferences - ${formId}`);
      }
    } catch (error) {
      hilog.error(0x0000, TAG, `Failed to save formId - ${error}`);
    }

    // 返回包含formTime的FormData（非空）
    let formData = new FormData();
    formData.formId = formId;
    formData.formTime = Date.now().toString();
    formData.cardList = []; // 初始为空
    hilog.info(0x0000, TAG, `onAddForm returning FormData with formTime: ${formData.formTime}, formId: ${formData.formId}`);
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(formId: string) {
    hilog.info(0x0000, TAG, `FormAbility onUpdateForm, formId = ${formId}`);
    try {
      let util = PreferencesUtil.getInstance();
      let preferences = util.getPreferences(this.context);
      if (!preferences) {
        hilog.error(0x0000, TAG, `preferences is null`);
        return;
      }

      let dataJson = util.preferencesGet(preferences, CommonConstants.DATA_KEY, '{}') as string;
       hilog.info(0x0000, TAG, `dataJson length: ${dataJson.length}`);
      let jsonData: JsonData = JSON.parse(dataJson) as JsonData;

      // 转换为FormCardData对象
      let formCardData = new FormCardData();
      formCardData.id = jsonData.id ?? '';
      formCardData.timestamp = jsonData.timestamp ?? 0;
      formCardData.active_module = jsonData.active_module ?? '';
      formCardData.rule_engine = jsonData.rule_engine;
      formCardData.dqn = jsonData.dqn;
      formCardData.vlm = jsonData.vlm;
      formCardData.favour = false;

       hilog.info(0x0000, TAG, `FormCardData id: ${formCardData.id}, module: ${formCardData.active_module}`);

      let formData = new FormData();
      formData.formId = formId;
      formData.formTime = Date.now().toString();
      formData.cardList = [formCardData];
       hilog.info(0x0000, TAG, `FormData formId: ${formData.formId}, cardList length: ${formData.cardList.length}`);

      let formMsg = formBindingData.createFormBindingData(formData);
      formProvider.updateForm(formId, formMsg).then(() => {
         hilog.info(0x0000, TAG, 'updateForm success');
      }).catch((error: Error) => {
         hilog.error(0x0000, TAG, `updateForm failed - ${error.message}`);
      });
    } catch (error) {
       hilog.error(0x0000, TAG, `onUpdateForm error - ${error.message}`);
    }
  }

   onRemoveForm(formId: string): void {
    hilog.info(0x0000, TAG, `onRemoveForm - ${formId}`);
  }

  onFormEvent(formId: string, message: string) {
    hilog.info(0x0000, TAG, `onFormEvent - ${formId}, ${message}`);
  }

  onCastToNormalForm(formId: string): void {
    hilog.info(0x0000, TAG, `onCastToNormalForm - ${formId}`);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
