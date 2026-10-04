# The Little Almanack Book Club's Campfire

A fork of [basecamp/once-campfire](https://github.com/basecamp/once-campfire), tracking its tagged
releases, with one change: **people can only join through a one-time invite made by an administrator.**

## What's different

- **One-time, email-locked invitations** replace the account-wide join link. An administrator creates
  an invitation for an email address (Account settings → Invite people). Its link works once, and the
  account is always created with the invited email address, whatever is typed in the form.
  Unused invitations never expire, but can be revoked.
- **Open sign-up (temporary seeding mode):** an admin can switch on one reusable public link
  (Account settings → Invite people → Open sign-up link) that lets anyone join with any email.
  It's the account's join code, off by default; turning it off makes the link 404 at once, and
  "new link" replaces it. Personal invitations keep working either way. Sign-ups are rate-limited,
  and `users.joined_via` records "invitation" or "open_link" for later pruning.
- **Permanent join address:** `/join` follows whatever sign-up is current: the open sign-up page
  while it's on; otherwise an admin-set `closed_signup_url` (e.g. a checkout page) or a friendly
  "not open right now" page. Share `/join` in articles so they never go stale.
- **Members can't invite anyone.** The join link is gone from Account settings and from the welcome
  note in the first room; both now show an "Invite people" button to administrators only.
  The old `/join/<account code>` links return 404.
- **Profile details:** optional location, "some books I like", website, X, LinkedIn and Instagram,
  filled in on each member's settings page and shown on their profile page (empty ones are hidden).
  Usernames can be typed as `@name` or pasted as profile links; only real http(s) links are accepted.
  The signup page also offers bio, location, books, X and Instagram (optional); invalid input re-renders the form with a message.
- **Brand icons:** X, LinkedIn and Instagram logos in `app/assets/images/brand-*.svg` are from
  [Tabler Icons](https://tabler.io/icons) (MIT License).
- **Bulk invitations:** `script/admin/create-invitations < emails.txt` prints `email,link` lines
  (needs `BASE_URL`, which ONCE sets).
- **Threads** (after [Sabha](https://github.com/sabha-co/sabha)'s): "Reply in thread" on any message in a
  room (not in DMs, not on a reply). Replies are messages with a `parent_message_id`, kept out of the
  room's timeline; the message shows "N replies · Last reply …" and the thread opens full screen at
  `/rooms/:room_id/messages/:message_id/thread`. A reply bolds the room and pushes only to the original
  poster, earlier repliers and anyone mentioned. Code: `app/models/message/threadable.rb`,
  `Messages::ThreadsController`, `app/views/messages/threads/`, `app/assets/stylesheets/threads.css`;
  tests in `test/models/message/threadable_test.rb`, `test/controllers/messages/threads_controller_test.rb`.
- **Menu with four circles:** Rooms (where it starts), DMs, Threads and Members replace the strip of ping
  avatars; one list shows at a time, kept for the visit (`sidebar_lists_controller.js`). Threads lists every
  thread in your rooms with a reply in the last 30 days, bold where you're in it and haven't read the
  latest (`ThreadParticipation`; Turbo prefetches don't count as reading). Members is everyone A–Z.
  Icons `app/assets/images/list-*.svg` are from Tabler Icons (MIT). Code: `app/views/users/sidebars/`,
  `app/assets/stylesheets/sidebar_lists.css`; tests in `test/controllers/users/sidebar_threads_test.rb`,
  `test/models/thread_participation_test.rb`.
- **"DM", not "Ping":** every place members see the word, including a labelled "DM <name>" profile button.

Code: `app/models/invitation.rb`, `app/controllers/accounts/invitations_controller.rb`,
`app/views/accounts/invitations/`, `UsersController#set_invitation`, the routes for `join/:token`,
`app/models/user/profile_details.rb`, `app/views/users/_profile_details.html.erb`,
`app/views/users/profiles/_details_fields.html.erb`, and tests in `test/models/invitation_test.rb`,
`test/models/user/profile_details_test.rb`, `test/controllers/users/profile_details_test.rb`, `test/controllers/users_controller_test.rb`,
`test/controllers/accounts/invitations_controller_test.rb`, `test/controllers/invite_visibility_test.rb`.

## Image

Every push to `main` publishes `ghcr.io/julito14/littlealmanack-campfire:main`, which the server
runs; ONCE picks up a new build within a day.

## Taking in a new Campfire release

```sh
git fetch upstream --tags
git merge v1.5.2          # the new release tag, never upstream/main
bin/rails test            # then push; CI runs the full suite before the image matters
git push
```
