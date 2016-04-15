import helloReduxReducer from './HelloReduxReducer';
import railsContextReducer from './RailsContextReducer';
import onboardingGuideReducer from './OnboardingGuideReducer';

// This is how you do a directory of reducers.
// The `import * as reducers` does not work for a directory, but only with a single file
export default {
  helloReduxData: helloReduxReducer,
  railsContext: railsContextReducer,
  onboardingGuidePage: onboardingGuideReducer
};
