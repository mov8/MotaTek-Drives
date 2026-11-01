import 'package:flutter_test/flutter_test.dart';
import 'package:drives/services/planner_service.dart';

void main() {
  Map pub = {
    'name': 'Blue Bell Inn',
    'kind': 'pub',
    'what': 'pub',
    'source': 'osm',
    'why': 'The Dambusters\' local',
    'story': 'Airmen signed the ceiling.',
    'sources': [
      {
        'url': 'https://www.visitlincolnshire.com/food-drink/blue-bell-inn/',
        'title': 'Blue Bell'
      }
    ],
  };

  test('a saved stop keeps its story, and where it came from', () {
    String description = describePlace(pub);
    expect(description, contains('Airmen signed the ceiling.'));
    expect(
        description,
        contains(
            'Source: https://www.visitlincolnshire.com/food-drink/blue-bell-inn/'));
  });

  test('a stop with nothing found has no story', () {
    String description = describePlace({...pub, 'story': '', 'sources': []});
    expect(description, isNot(contains('Source:')));
  });

  test('a source is named by where it is', () {
    expect(
        sourceName(
            'https://www.visitlincolnshire.com/food-drink/blue-bell-inn/'),
        'visitlincolnshire.com');
    expect(sourceName('https://camra.org.uk/pubs/1'), 'camra.org.uk');
  });
}
