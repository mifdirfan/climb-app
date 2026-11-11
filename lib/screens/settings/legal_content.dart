import '../../core/config/app_links.dart';

/// One heading + body paragraph in a [LegalDocument].
class LegalSection {
  const LegalSection(this.heading, this.body);
  final String heading;
  final String body;
}

/// Static, bundled legal text rendered by `LegalDocumentScreen`.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  final String title;
  final String lastUpdated;
  final List<LegalSection> sections;
}

// DRAFT CONTENT — placeholder text describing what the app actually does.
// Have it reviewed (Malaysia PDPA 2010) and replace before public release.

const privacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  lastUpdated: '11 November 2026',
  sections: [
    LegalSection(
      'What we collect',
      'When you create an account we store your email address, username and '
          'optional display name. When you use ClimbMY we store the content you '
          'create: sends and ticks, indoor sessions, saved crags, and hazard '
          'reports (including any location or photos you attach).',
    ),
    LegalSection(
      'How we use it',
      'Your data is used to run the app: to show your logbook, sync your saved '
          'crags across devices, and share community hazard reports with other '
          'climbers. We do not sell your personal data.',
    ),
    LegalSection(
      'What others can see',
      'Hazard reports and route information you contribute are visible to other '
          'users. Your email address is never shown publicly.',
    ),
    LegalSection(
      'Where it is stored',
      'Data is stored with our hosting provider, Supabase, and protected by '
          'row-level security so only you can change your own records.',
    ),
    LegalSection(
      'Deleting your data',
      'You can delete your account at any time from Settings → Delete Account. '
          'This permanently removes your profile, logbook, sessions and saved '
          'crags. Hazard reports you submitted stay up for safety, but are no '
          'longer linked to you.',
    ),
    LegalSection(
      'Contact',
      'Questions about your data? Email ${AppLinks.supportEmail}.',
    ),
  ],
);

const termsOfService = LegalDocument(
  title: 'Terms & Conditions',
  lastUpdated: '11 November 2026',
  sections: [
    LegalSection(
      'Climbing is dangerous',
      'Rock climbing and bouldering carry a risk of serious injury or death. '
          'Route grades, topos, beta and hazard reports in ClimbMY are '
          'community-contributed and may be wrong or out of date. Always assess '
          'conditions yourself and climb within your ability.',
    ),
    LegalSection(
      'No guarantee of accuracy',
      'ClimbMY is provided "as is". We do not guarantee that any information, '
          'including access status and hazard alerts, is complete or current.',
    ),
    LegalSection(
      'Your account',
      'You are responsible for keeping your login secure and for everything '
          'posted from your account.',
    ),
    LegalSection(
      'Your content',
      'You keep ownership of what you post. By posting, you allow ClimbMY to '
          'display it to other users. Do not post content that is unlawful, '
          'misleading, or that you do not have the right to share.',
    ),
    LegalSection(
      'Access & landowners',
      'Respect access agreements, private land and local regulations. A crag '
          'appearing in the app does not mean climbing there is permitted.',
    ),
    LegalSection(
      'Changes',
      'We may update these terms. Continuing to use the app after an update '
          'means you accept the new terms.',
    ),
  ],
);
