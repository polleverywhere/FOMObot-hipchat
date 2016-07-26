FOMObot for HipChat
===================

A HipChat bot that monitors rooms for message activity spikes. When activity spikes within a channel, FOMObot posts a message to the FOMO room to let anyone in that channel know that they could be missing out on an important conversation.


Requirements
============

* Elixir 1.0.1


Setup
=====

1. Create a "FOMO" room in HipChat
2. Create a new FOMObot HipChat user
3. Log in to hipchat.com as the FOMObot user
4. Navigate to "Account Settings | XMPP/Jabber info"
5. `cp config/config.exs.template config/config.exs`
6. Edit `config/config.exs` and replace all `****` with information from the web page.


Run it
======

```
$ cd FOMObot-hipchat
$ mix deps.get
$ iex -S mix
```


Docker
=======

To build the container cd into the docker directory and run:

```
$ ./build.bash
```

You will need to figure out how you will get the config.exs file into the container, either from your own private repo or mount it as a volume when spinning up the container.


Credits
=======

- Based on thoughtbot's [FOMObot for Slack](https://github.com/thoughtbot/FOMObot).
- Original source code copied from [ikbot](https://github.com/inaka/ikbot).
- Product of a [Poll Everywhere](https://www.polleverywhere.com) hackathon in the Santa Cruz Mountains.
