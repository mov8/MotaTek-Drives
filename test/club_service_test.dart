import 'package:drives/services/club_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The user's clubs, as the server sends them (api.clubs.summary) - what the
/// club picker shows, and whether the Markdown editor is offered
void main() {
  Map<String, dynamic> summary({String showing = 'mg', bool canEdit = true}) => {
        'clubs': [
          {'id': 'mg', 'name': 'MG Car Club', 'role': 'admin'},
          {'id': 'tr', 'name': 'Triumph Owners', 'role': 'member'},
        ],
        'showing': showing,
        'drives': 'drives',
        'can_edit_pages': canEdit,
      };

  tearDown(() => ClubService().clear());

  test('the clubs, whose pages are shown, and who may edit them', () {
    ClubService clubs = ClubService()..read(summary());
    expect(clubs.inAnyClub, isTrue);
    expect([for (Club c in clubs.clubs) '${c.name}:${c.isAdmin}'],
        ['MG Car Club:true', 'Triumph Owners:false']);
    expect(clubs.showingName, 'MG Car Club');
    expect(clubs.canEditPages, isTrue);
  });

  test("Drives' own pages are called Drives", () {
    ClubService clubs = ClubService()
      ..read(summary(showing: 'drives', canEdit: false));
    expect(clubs.showingName, 'Drives');
    expect(clubs.canEditPages, isFalse);
  });

  test('cleared - nobody logged in - back to Drives, editing nothing', () {
    ClubService clubs = ClubService()..read(summary());
    clubs.clear();
    expect(clubs.inAnyClub, isFalse);
    expect(clubs.showing, 'drives');
    expect(clubs.canEditPages, isFalse);
  });

  test("a club member doesn't get Drives' pages to choose; staff do", () {
    ClubService clubs = ClubService()
      ..read({...summary(), 'can_show_drives': false});
    expect(clubs.canShowDrives, isFalse);
    clubs.read({...summary(), 'can_show_drives': true});
    expect(clubs.canShowDrives, isTrue);
    clubs.clear();
    expect(clubs.canShowDrives, isTrue); // nobody logged in: Drives' pages
  });

  test('a user in no club', () {
    ClubService clubs = ClubService()
      ..read({'clubs': [], 'showing': 'drives', 'drives': 'drives'});
    expect(clubs.inAnyClub, isFalse);
    expect(clubs.canEditPages, isFalse);
  });
}
