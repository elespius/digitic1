// Shows the mapping from the exported object to the name used by the server rendering.
import ReactOnRails from 'react-on-rails';
// Example of React + Redux
import ReduxApp from './ExampleReduxApp';

import OnboardingGuideApp from './OnboardingGuideApp';
import OnboardingTopBar from '../components/OnboardingTopBar/OnboardingTopBar';

ReactOnRails.register({
  ReduxApp,
  OnboardingGuideApp,
  OnboardingTopBar,
});

ReactOnRails.registerStore({
});
