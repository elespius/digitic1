import React, { PropTypes } from 'react';
import r from 'r-dom';
import _ from 'lodash';

import GuideStatusPage from './GuideStatusPage';
import GuideSloganAndDescriptionPage from './GuideSloganAndDescriptionPage';
import GuideCoverPhotoPage from './GuideCoverPhotoPage';
import GuideFilterPage from './GuideFilterPage';
import GuidePaypalPage from './GuidePaypalPage';
import GuideListingPage from './GuideListingPage';
import GuideInvitationPage from './GuideInvitationPage';

import { t } from '../../utils/i18n';


// Select child component (page/view) to be rendered
// Returns object (including child component) based on props.data & nextStep
const selectChild = function selectChild(data, nextStep) {
  const { path, onboarding_data } = data;
  const pageData = (path.length > 0) ?
    _.find(onboarding_data, (pd) => pd.sub_path === path.substring(1)) :
    {};

  switch (path) {
    case '/slogan_and_description':
      return { Page: GuideSloganAndDescriptionPage, pageData };
    case '/cover_photo':
      return { Page: GuideCoverPhotoPage, pageData };
    case '/filter':
      return { Page: GuideFilterPage, pageData };
    case '/paypal':
      return { Page: GuidePaypalPage, pageData };
    case '/listing':
      return { Page: GuideListingPage, pageData };
    case '/invitation':
      return { Page: GuideInvitationPage, pageData };
    default:
      return { Page: GuideStatusPage, onboarding_data, nextStep };
  }
};

// Get link and title of next recommended onboarding step
const nextStep = function nextStep(data, translateFunc) {
  debugger;
  const nextIncomplete = _.find(data, function(step) {
    return !step.complete;
  }) || {};

  switch (nextIncomplete.step) {
  case "slogan_and_description":
    return {
      title: t("admin.onboarding.guide.next_step.slogan_and_description"),
      link: nextIncomplete.sub_path,
    };
  case "cover_photo":
    return {
      title: t("admin.onboarding.guide.next_step.cover_photo"),
      link: nextIncomplete.sub_path,
    };
  case "filter":
    return {
      title: t("admin.onboarding.guide.next_step.filter"),
      link: nextIncomplete.sub_path,
    };
  case "paypal":
    return {
      title: t("admin.onboarding.guide.next_step.paypal"),
      link: nextIncomplete.sub_path,
    };
  case "listing":
    return {
      title: t("admin.onboarding.guide.next_step.listing"),
      link: nextIncomplete.sub_path,
    };
  case "invitation":
    return {
      title: t("admin.onboarding.guide.next_step.invitation"),
      link: nextIncomplete.sub_path,
    };
  default:
    return false;
  }
};

// getPaths: initial path containing given pathFragment & relative (deeper) path
const getPaths = function getPaths(props, pathFragment) {
  const pathParts = props.data.original_path.split(pathFragment);
  const initialPath = pathParts[0] + pathFragment;
  return { initialPath, componentSubPath: pathParts[1] };
};

class OnboardingGuide extends React.Component {

  constructor(props, context) {
    super(props, context);

    this.setPushState = this.setPushState.bind(this);
    this.handlePopstate = this.handlePopstate.bind(this);
    this.handlePageChange = this.handlePageChange.bind(this);

    const paths = getPaths(props, 'getting_started_guide');
    this.initialPath = paths.initialPath;
    this.componentSubPath = paths.componentSubPath;

    // Figure out the next step. I.e. what is the action we recommend for admins
    this.nextStep = nextStep(this.props.data.onboarding_data);

    // Add current path to window.history. Initially it contains null as a state
    this.setPushState(
      { path: this.componentSubPath },
      this.componentSubPath,
      this.componentSubPath);
  }

  componentDidMount() {
    window.addEventListener('popstate', this.handlePopstate);
  }

  componentWillUpdate(nextProps) {
    // Back button clicks should not be saved with history.pushState
    if (nextProps.data.pathHistoryForward) {
      const path = nextProps.data.path;
      this.setPushState({ path }, path, path);
    }
  }

  componentWillUnmount() {
    window.removeEventListener('popstate', this.handlePopstate);
  }

  setPushState(state, title, path) {
    // React has an internal variable 'canUseDOM', which we emulate here.
    const canUseDOM = !!(typeof window !== 'undefined' &&
                          window.document &&
                          window.document.createElement);
    const canUsePushState = !!(typeof history !== 'undefined' &&
                                history.pushState);

    if (canUseDOM && canUsePushState) {
      window.history.pushState(state, title, `${this.initialPath}${path}`);
    }
  }

  handlePopstate(event) {
    if (event.state != null && event.state.path != null) {
      this.props.actions.updateGuidePage(event.state.path, false);
    } else if (event.state == null && typeof this.props.data.pathHistoryForward !== 'undefined') {
      // null state means that page component's root path is reached and
      // previous page is actually on Rails side - i.e. one step further
      // Safari fix: if pathHistoryForward is not defined, its initial page load
      window.history.back();
    }
  }

  handlePageChange(path) {
    this.props.actions.updateGuidePage(path, true);
  }

  render() {
    const { Page, translations, ...opts } = selectChild(this.props.data, this.nextStep);
    return r(Page, {
      changePage: this.handlePageChange,
      initialPath: this.initialPath,
      name: this.props.data.name,
      infoIcon: this.props.data.info_icon,
      ...opts,
    });
  }
}

OnboardingGuide.propTypes = {
  actions: PropTypes.shape({
    updateGuidePage: PropTypes.func.isRequired,
  }).isRequired,
  railsContext: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  data: PropTypes.shape({
    path: PropTypes.string.isRequired,
    original_path: PropTypes.string.isRequired,
    pathHistoryForward: PropTypes.bool,
    name: PropTypes.string.isRequired,
    info_icon: PropTypes.string.isRequired,
    onboarding_data: PropTypes.objectOf(PropTypes.shape({
      info_image: PropTypes.string,
      cta: PropTypes.string.isRequired,
      alternative_cta: PropTypes.string,
      complete: PropTypes.bool.isRequired,
    }).isRequired).isRequired,
  }).isRequired,
};

export default OnboardingGuide;
