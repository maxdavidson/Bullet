part of bullet.client.models;

class Ad extends Model {
  get title => state['title'];
  get price => state['price'];
  get date => state['date'];
}

@Injectable()
class AdCollection extends Collection<Ad> {
  AdCollection(DatabaseService db)
    : super('ads', db, () => new Ad());
}