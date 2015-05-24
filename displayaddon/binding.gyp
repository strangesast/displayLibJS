{
  "targets": [
    {
      "target_name": "displayaddon",
      "sources": [ "displayaddon.cc", "msgqueue.cc", "mysocket.cc", "displayusb.cc" ],
    "conditions": [
      ['OS!="win"', {
        'include_dirs': [
          '/usr/include/libusb-1.0',
        ],
        'libraries': [
         '-lusb-1.0',
        ],
        'cflags_cc' : [
         '-fpermissive',
        ]
      }],
    ]
  }]
}
