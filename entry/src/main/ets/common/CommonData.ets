/**
 * Form data class for widget
 */
export class FormData {
  formId: string = '';
  formTime: string = '';
  cardList: FormCardData[] = [];
}

/**
 * Unified action data interface
 */
export interface ActionData {
  action_type: 'probe' | 'recommend' | 'none';
  action_name: string;
  image: string | null;  // base64 encoded image or null
  scene_category: string;
}

/**
 * Card data for widget
 */
export class FormCardData {
  id: string = '';
  timestamp: number = 0;
  action_data: ActionData = {
    action_type: 'none',
    action_name: '',
    image: null,
    scene_category: ''
  };
  favour: boolean = false;
}
