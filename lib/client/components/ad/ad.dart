part of bullet.client.components;

@Component(
  selector: 'ad',
  publishAs: 'ctrl',
  templateUrl: 'packages/bullet/client/components/ad/ad.html',
  cssUrl: 'packages/bullet/client/components/ad/ad.css',
  map: const {
    'model': '=>!model' // Need only to track once
  }) 
class AdComponent {
  Ad model;
  get date => model.date;
  get title => model.title;
  get price => model.price;
}
