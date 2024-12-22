# Bummer

A Gleam client library for controlling [buttplug.io][buttplugio] supported
devices.

[![Package Version](https://img.shields.io/hexpm/v/bummer)](https://hex.pm/packages/bummer)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/bummer/)

Further documentation can be found at <https://hexdocs.pm/bummer>.


## Installation

```sh
gleam add bummer@1
```


## Usage

```gleam
import bummer

case bummer.connect("ws://127.0.0.1:12345/") {
  Ok(socket) -> {
    io.println("Connected to intiface-engine websocket")
    io.println("Initiating a test sequence")

    bummer.scan(socket, 5000)
    bummer.vibrate(socket, 500)
    bummer.rotate(socket, 500)

    io.println("Test sequence finished")
  }
  Error(_) ->
    "Cannot connect to intiface-engine websocket. Is it running?"
    |> io.println_error
```


## The ten-thousand-foot view

A toy communicates with your computer via Bluetooth LE. Some manufacturers
require [pairing before use][pairing], some don't. You don't use the system
Bluetooth manager to connect to the device.

Clients like [buttplug-py][buttplugpy], [buttplug-js][buttplugjs], or this Gleam
client, don't control the toy directly. They only communicate with a server like
[intiface-engine][engine] via websockets. The server then does the heavy
lifting.

You can run the server like this:

```
cargo install intiface-engine
~/.cargo/bin/intiface-engine --websocket-port 12345 --use-bluetooth-le
```

Only then you can use your client.

This package is supposed to be used only as a library for your client tools but
comes with a short executable to test your setup more easily.

```
gleam run
```

Run it twice to be sure.


## Resources

- [API spec][spec] - Describes the architecture, messages schema, etc
- [A Python client][buttplugpy] - Logs sent and received messages, can be used
  for inspiration
- [Clients for other languages][libraries] - And many other projects
- [List of supported devices][supported-devices] - A comprehensive list of all
  supported manufacturers and devices with links where to buy them


## Troubleshooting

- Make sure you have a [supported Bluetooth dongle][supported-dongles]
- Make sure the toy isn't [paired to another device][pairing-reset]
- Try [disabling unsupported Bluetooth adapters][disabling-adapters]
- Try `sudo rfkill unblock bluetooth` and
  `sudo systemctl restart bluetooth.service`



[buttplugio]: https://buttplug.io/
[buttplugpy]: https://github.com/Siege-Wizard/buttplug-py
[buttplugjs]: https://github.com/buttplugio/buttplug-js
[engine]: https://github.com/intiface/intiface-engine
[spec]: https://docs.buttplug.io/docs/spec/
[supported-dongles]: https://docs.intiface.com/docs/intiface-central/hardware/bluetooth/#what-type-of-bluetooth-dongle-should-i-use
[pairing]: https://faq.docs.buttplug.io/hardware/bluetooth.html#when-should-i-pair-my-device-with-my-operating-system
[pairing-reset]: https://faq.docs.buttplug.io/hardware/satisfyer.html#how-do-i-connect-my-satisfyer-device-to-a-desktop-laptop
[disabling-adapters]: https://unix.stackexchange.com/questions/314373/permanently-disable-built-in-bluetooth-and-use-usb/617215#617215
[libraries]: https://github.com/buttplugio/awesome-buttplug?tab=readme-ov-file#development-and-libraries
[supported-devices]: https://iostindex.com/?filter0Availability=Available,DIY&filter1Connection=Digital
