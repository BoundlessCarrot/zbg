# zbg - A Backgammon engine, for fun and (dubious) profit

This will be the backend for a backgammon portion of my website. I find the game of backgammon extremely interesting, but the current solutions all have a maximalist, "operated by casino" look and feel. There's also bgammon.org, which, while very good, still feels like too much. I want a backgammon site that's similar in feel to lichess!

There are some specifics I want for my implementation too:
- [ ] Engine and API written in zig, using Zap for the routing
- [ ] Supabase for DB stuff - user/elo pairs, game histories
- [ ] No "real" accounts! I want to give people a unique ID number that's not visible to anyone else. Most other info will be stored in a user cookie, and updates the one on the db. You can then track stats while not having to deal with emails and passwords, while also allowing people to recover their game history if they clear their brower history/cookies
