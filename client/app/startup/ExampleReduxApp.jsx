// Top level component for client side.
// NOTE: it's possible to do different apps for rendering client vs server side
// NOTE: these are basically the same, but they are shown here


import React from 'react';
import { combineReducers, applyMiddleware, createStore } from 'redux';
import { Provider } from 'react-redux';
import middleware from 'redux-thunk';

// Uses the index
import reducers from '../reducers/reducersIndex';
import composeInitialState from '../store/composeInitialState';

import HelloReduxContainer from '../components/helloReduxExampleComponent/HelloReduxContainer';

/*
 *  Export a function that takes the props and returns a ReactComponent.
 *  This is used for the client rendering hook after the page html is rendered.
 *  React will see that the state is the same and not do anything.
 *
 */
export default (props, railsContext) => {
  const combinedReducer = combineReducers(reducers);
  const combinedProps = composeInitialState(props, railsContext);

  // This is where we'll put in the middleware for the async function. Placeholder.
  // store will have helloWorldData as a top level property
  const store = applyMiddleware(middleware)(createStore)(combinedReducer, combinedProps);

  // Provider uses the this.props.children, so we're not typical React syntax.
  // This allows redux to add additional props to the HelloReduxContainer.
  return (
      <Provider store={store}>
        <HelloReduxContainer />
      </Provider>
    );
};
