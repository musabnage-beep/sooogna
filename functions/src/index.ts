import { initializeApp } from 'firebase-admin/app';

initializeApp();

export { onReviewWritten } from './reviews';
export { onChatMessageCreated } from './chat';
export { onAdStatusChanged, onAdCreated } from './ads';
export { onReportCreated } from './reports';
