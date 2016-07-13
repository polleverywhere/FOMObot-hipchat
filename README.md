FOMObot for HipChat
===================

A HipChat bot that monitors rooms for message activity spikes. When activity spikes within a channel, FOMObot posts a message to the FOMO room to let anyone in that channel know that they could be missing out on an important conversation.

Based on [FOMObot for Slack](https://github.com/thoughtbot/FOMObot).


Requirements
============

* Elixir 1.0.1


Setup
=====

1. Create a FOMObot room in HipChat
2. Create a new HipChat user
3. Login as the FOMObot user and navigate to Account Settings | XMPP/Jabber info
4. `cp config/config.exs.template config/config.exs`
5. Edit `config/config.exs` and replace `****` with information from the web page


Run it
====

```
$ cd FOMObot-hipchat
$ mix deps.get
$ iex -S mix
```
