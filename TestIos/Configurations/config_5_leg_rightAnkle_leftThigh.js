{
    "bones": [
    {
             "name": "LeftThigh",
             "color1": "Cyan",
             "color2": "Cyan",
             "frequency": 50
    },
      {
            "name": "Hip",
            "color1": "Blue",
            "color2": "Blue",
            "frequency": 50
        },
        {
            "name": "RightThigh",
            "color1": "Red",
            "color2": "Red",
            "frequency": 50
        },
        {
            "name": "RightLowerLeg",
            "color1": "Green",
            "color2": "Green",
            "frequency": 50
        },
        {
            "name": "RightFootTop",
            "color1": "Pink",
            "color2": "Pink",
            "frequency": 50
        },
    ],
    "master_bone": "Hip",
    "special": {
        "bone": "Hip",
        "orientation": "Front"
    },
    "constraints": [
        {
            "source": "Hip",
            "target": "LeftHip",
            "type": "COPY"
        },
        {
            "source": "Hip",
            "target": "RightHip",
            "type": "COPY"
        },
        {
            "type": "INTERP",
            "target": "Tummy",
            "source": "ChestBottom",
            "f": 0.5
        },
        {
            "type": "INTERP",
            "target": "ChestTop",
            "source": "Hip",
            "f": -0.42
        }
    ]
    "custom":{
        "config_name":"Lower body(with hip)"
    }
}



