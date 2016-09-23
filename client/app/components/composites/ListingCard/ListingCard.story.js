import r, { div, h1, h2, p } from 'r-dom';
import { mount } from 'enzyme';

import { storify } from '../../Styleguide/withProps';

import ListingCard from './ListingCard';
import css from './ListingCard.story.css';

const containerStyle = { style: { background: 'white' } };

storiesOf('Search results')
  .add('Summary', () => (
    div({
      className: css.previewPage,
    }, [
      h1({ className: css.title }, 'Listings'),
      p({ className: css.description }, 'Search results are shown in grid view using listing cards. They contain square images and the result set is paged.'),
      h2({ className: css.sectionTitle }, 'ListingCard'),
      div({
        className: css.singleListingWrapper,
      }, [
        r(ListingCard, Object.assign({},
          {
            id: 'lkjg84573874yjdf',
            title: 'Title',
            listingURL: 'http://marketplace.com/listing/342iu4',
            imageURL: 'http://placehold.it/408x408',
            image2xURL: 'http://placehold.it/816x816',
            noImageText: 'No picture',
            avatarURL: 'http://placehold.it/40x40',
            profileURL: '#profile1',
            price: 21474836.47,
            priceUnit: '€',
            per: '/ hundred centimeters',
            distance: 12972,
            distanceUnit: 'mi',
            color: '#347F9D',
            className: css.listing,
          },
        )),
      ]),
      h2({ className: css.sectionTitle }, 'ListingPage (not ready yet)'),
      div({
        className: css.wrapper,
      }, [
        r(ListingCard, Object.assign({},
          {
            id: 'lkjg84573874yjdf',
            title: 'Picture load fails',
            listingURL: 'http://marketplace.com/listing/342iu4',
            imageURL: 'http://failingimage.com/image.png',
            image2xURL: 'http://failingimage.com/image@2x.png',
            noImageText: 'No picture',
            avatarURL: 'http://placehold.it/40x40',
            profileURL: '#profile1',
            price: 199,
            priceUnit: '€',
            distance: 9,
            distanceUnit: 'km',
            color: '#347F9D',
            className: css.listing,
          },
        )),
        r(ListingCard, Object.assign({},
          {
            id: 'lkjg84573874yjdf',
            title: 'No picture',
            listingURL: 'http://marketplace.com/listing/342iu4',
            noImageText: 'No picture',
            avatarURL: 'http://placehold.it/40x40',
            profileURL: '#profile1',
            price: 19,
            priceUnit: '€',
            per: '/ day',
            distance: 0.67,
            distanceUnit: 'km',
            color: '#347F9D',
            className: css.listing,
          },
        )),
        r(ListingCard, Object.assign({},
          {
            id: 'lkjg84573874yjdf',
            title: 'Title',
            listingURL: 'http://marketplace.com/listing/342iu4',
            imageURL: 'http://placehold.it/408x408',
            image2xURL: 'http://placehold.it/816x816',
            noImageText: 'No picture',
            avatarURL: 'http://placehold.it/40x40',
            profileURL: '#profile1',
            price: 21474836.47,
            priceUnit: '€',
            per: '/ hundred centimeters',
            distance: 12972,
            distanceUnit: 'mi',
            color: '#347F9D',
            className: css.listing,
          },
        )),
        r(ListingCard, Object.assign({},
          {
            id: 'iuttei7538746tr',
            title: 'Cisco SF300-48 SRW248G4-K9-NA 10/100 Managed Switch 48 Port',
            listingURL: 'http://marketplace.com/listing/342iu4',
            imageURL: 'http://placehold.it/408x408',
            image2xURL: 'http://placehold.it/816x816',
            noImageText: 'No picture',
            avatarURL: 'http://placehold.it/40x40',
            profileURL: '#profile2',
            price: 49,
            priceUnit: '€',
            per: '/ day',
            distance: 0.02,
            distanceUnit: 'km',
            color: '#347F9D',
            className: css.listing,
          },
        )),
      ]),
    ])
  ))
  .add('ListingCard - basic', () => (
      r(storify(
        r(ListingCard, Object.assign({},
          {
            id: 'lkjg84573874yjdf',
            title: 'Title',
            listingURL: 'http://marketplace.com/listing/342iu4',
            imageURL: 'http://placehold.it/408x408',
            image2xURL: 'http://placehold.it/816x816',
            noImageText: 'No picture',
            avatarURL: 'http://placehold.it/40x40',
            profileURL: '#profile1',
            price: 21474836.47,
            priceUnit: '€',
            per: '/ hundred centimeters',
            distance: 12972,
            distanceUnit: 'mi',
            color: '#347F9D',
            className: css.listing,
          },
        )),
        containerStyle
      ))
  ))
  .add('ListingCard - no image', () => (
      r(storify(
        r(ListingCard, Object.assign({},
          {
            id: 'lkjg84573874yjdf',
            title: 'No picture',
            listingURL: 'http://marketplace.com/listing/342iu4',
            noImageText: 'No picture',
            avatarURL: 'http://placehold.it/40x40',
            profileURL: '#profile1',
            price: 19,
            priceUnit: '€',
            per: '/ day',
            distance: 0.67,
            distanceUnit: 'km',
            color: '#347F9D',
            className: css.listing,
          },
        )),
        containerStyle
      ))
  ))
  .add('ListingCard - image fail', () => {
    const story =
      r(ListingCard, Object.assign({},
        {
          id: 'lkjg84573874yjdf',
          title: 'Picture load fails',
          listingURL: 'http://marketplace.com/listing/342iu4',
          imageURL: 'http://failingimage.com/image.png',
          image2xURL: 'http://failingimage.com/image@2x.png',
          noImageText: 'No picture',
          avatarURL: 'http://placehold.it/40x40',
          profileURL: '#profile1',
          price: 199,
          priceUnit: '€',
          distance: 9,
          distanceUnit: 'km',
          color: '#347F9D',
          className: css.listing,
        },
      ));

    specs(() => describe('Failing image', () => {
      it('Should display "No picture"', () => {
        const output = mount(story);
        output.setState({ imageStatus: 'failed' });
        expect(output.text()).to.include('No picture');
      });
      it('Should display formatted price', () => {
        const output = mount(story);
        expect(output.text()).to.include('€ 199');
      });
      it('Should display formatted distance', () => {
        const output = mount(story);
        expect(output.text()).to.include('9 km');
      });
    }));

    return r(storify(story, containerStyle));
  });
