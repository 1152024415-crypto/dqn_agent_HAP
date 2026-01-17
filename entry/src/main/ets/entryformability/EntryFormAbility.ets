import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { FormData, FormCardData, RuleEngineData, DQNData, VLMData } from '../common/CommonData';
import { CommonConstants } from '../common/CommonConstants';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';

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
        util.preferencesPut(preferences, CommonConstants.FORM_ID_KEY, formId);
        console.log(`${TAG}: Saved formId to Preferences - ${formId}`);
      }
    } catch (error) {
      console.error(`${TAG}: Failed to save formId - ${error}`);
    }

    return formBindingData.createFormBindingData('');
  }

  onUpdateForm(formId: string) {
    console.log(`${TAG}: onUpdateForm called with formId: ${formId}`);
    try {
      let util = PreferencesUtil.getInstance();
      let preferences = util.getPreferences(this.context);
      if (!preferences) {
        console.error(`${TAG}: preferences is null`);
        return;
      }

      let dataJson = util.preferencesGet(preferences, CommonConstants.DATA_KEY, '{}') as string;
      console.log(`${TAG}: dataJson length: ${dataJson.length}`);
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

      console.log(`${TAG}: FormCardData id: ${formCardData.id}, module: ${formCardData.active_module}`);

      let formData = new FormData();
      formData.formTime = Date.now().toString();
      formData.cardList = [formCardData];
      console.log(`${TAG}: FormData cardList length: ${formData.cardList.length}`);

      let formMsg = formBindingData.createFormBindingData(formData);
      formProvider.updateForm(formId, formMsg).then(() => {
        console.log('EntryFormAbility: updateForm success');
      }).catch((error: Error) => {
        console.error('EntryFormAbility: updateForm failed -', error);
      });
    } catch (error) {
      console.error('EntryFormAbility: onUpdateForm error -', error);
    }
  }

  onRemoveForm(formId: string): void {
    console.log('EntryFormAbility: onRemoveForm -', formId);
  }

  onFormEvent(formId: string, message: string) {
    console.log('EntryFormAbility: onFormEvent -', formId, message);
  }

  onCastToNormalForm(formId: string): void {
    console.log('EntryFormAbility: onCastToNormalForm -', formId);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
