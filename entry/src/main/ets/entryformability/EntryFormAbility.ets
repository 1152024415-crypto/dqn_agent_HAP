import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { FormData, FormCardData, ActionData } from '../common/CommonData';
import { CommonConstants } from '../common/CommonConstants';
import { PreferencesUtil } from '../common/utils/PreferencesUtil';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DqnState } from '../common/CommonData';

const TAG: string = 'HTTPPollService';

// Interface for parsed JSON data
interface JsonData {
  id?: string;
  timestamp?: number;
  action_type?: string;
  action_name?: string;
  image?: string | null;
  scene_category?: string;
  dqn_state?: DqnState;
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
    hilog.info(0x0000, TAG, `=======================================[START] onUpdateForm for formId = ${formId}`);
    try {
      // 1. 获取 Preferences 实例
      let util = PreferencesUtil.getInstance();
      let preferences = util.getPreferences(this.context);
      if (!preferences) {
        hilog.error(0x0000, TAG, `[FAIL] Preferences is null. Cannot update form.`);
        return;
      }

      // 2. 从 Preferences 读取完整的 JSON 字符串
      let dataJson = util.preferencesGet(preferences, CommonConstants.DATA_KEY, '{}') as string;
      hilog.info(0x0000, TAG, `[Step 1] Read from Prefs: ${dataJson.substring(0, 300)}`);

      if (dataJson === '{}') {
        hilog.warn(0x0000, TAG, `[WARN] No data in Preferences. Nothing to update.`);
        return;
      }

      // 3. 解析 JSON
      let jsonData: JsonData;
      try {
        jsonData = JSON.parse(dataJson) as JsonData;
        hilog.info(0x0000, TAG, `[Step 2] JSON parsed successfully.`);
      } catch (e) {
        hilog.error(0x0000, TAG, `[FAIL] JSON.parse failed: ${JSON.stringify(e)}`);
        return; // 解析失败，直接退出
      }

      // 4. [关键] 构造 ActionData，并严格检查 dqn_state
      const actionData: ActionData = {
        action_type: (jsonData.action_type as 'probe' | 'recommend' | 'none') ?? 'none',
        action_name: jsonData.action_name ?? 'N/A',
        image: jsonData.image ?? null,
        scene_category: jsonData.scene_category ?? 'N/A',
        dqn_state: jsonData.dqn_state ? {
          activity: jsonData.dqn_state.activity ?? '未知(act)',
          location: jsonData.dqn_state.location ?? '未知(loc)',
          light: jsonData.dqn_state.light ?? '未知(light)',
          scene: jsonData.dqn_state.scene ?? '未知(scene)'
        } : {
          activity: '解析失败',
          location: '解析失败',
          light: '解析失败',
          scene: '解析失败'
        }
      };

      // 5. [关键调试日志] 打印解析后的 dqn_state 内容
      if (actionData.dqn_state) {
        const stateLog = `activity=${actionData.dqn_state.activity}, location=${actionData.dqn_state.location}, light=${actionData.dqn_state.light}, scene=${actionData.dqn_state.scene}`;
        hilog.info(0x0000, TAG, `[Step 3] Parsed dqn_state: ${stateLog}`);
      } else {
        hilog.error(0x0000, TAG, `[FAIL] dqn_state is missing after parsing!`);
      }

      // 6. 组装最终的卡片数据
      let formCardData = new FormCardData();
      formCardData.id = jsonData.id ?? '';
      formCardData.timestamp = jsonData.timestamp ?? 0;
      formCardData.action_data = actionData;

      let formData = new FormData();
      formData.formId = formId;
      formData.formTime = Date.now().toString();
      formData.cardList = [formCardData];

      // 7. 发起卡片更新
      let formBindingDataObj = formBindingData.createFormBindingData(formData);

      formProvider.updateForm(formId, formBindingDataObj)
        .then(() => {
          hilog.info(0x0000, TAG, `[SUCCESS] updateForm call successful for formId: ${formId}`);
        })
        .catch((error: Error) => {
          hilog.error(0x0000, TAG, `[FAIL] Final updateForm call failed: ${error.message}`);
        });

    } catch (error) {
      hilog.error(0x0000, TAG, `[CRITICAL] Unhandled error in onUpdateForm: ${error.message}`);
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
