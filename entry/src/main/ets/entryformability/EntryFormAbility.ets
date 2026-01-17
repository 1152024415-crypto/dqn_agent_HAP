import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { FormData, FormCardData } from '../common/CommonData';
import { CommonConstants } from '../common/CommonConstants';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';

const TAG: string = 'EntryFormAbility';

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
    try {
      let util = PreferencesUtil.getInstance();
      let preferences = util.getPreferences(this.context);
      if (!preferences) {
        return;
      }

      let dataJson = util.preferencesGet(preferences, CommonConstants.DATA_KEY, '{}') as string;
      let data = JSON.parse(dataJson) as FormCardData;

      let formData = new FormData();
      formData.formTime = Date.now().toString();
      formData.cardList = [data];
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
