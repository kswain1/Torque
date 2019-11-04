{
    "bones": [
        {
            "name": "ChestBottom",
            "color1": "Blue",
            "color2": "Blue",
            "frequency": 40
        },
        {
            "name": "LeftUpperArm",
            "color1": "Pink",
            "color2": "Pink",
            "frequency": 40
        },
        {
            "name": "LeftForeArm",
            "color1": "Yellow",
            "color2": "Yellow",
            "frequency": 40
        },
        {
            "name": "RightUpperArm",
            "color1": "Red",
            "color2": "Red",
            "frequency": 40
        },
        {
            "name": "RightForeArm",
            "color1": "Green",
            "color2": "Green",
            "frequency": 40
        },
        {
            "name": "Hip",
            "color1": "Cyan",
            "color2": "Cyan",
            "frequency": 40
        },
        {
            "name": "RightThigh",
            "color1": "Red",
            "color2": "Black",
            "frequency": 40
        },
        {
            "name": "RightLowerLeg",
            "color1": "Green",
            "color2": "Black",
            "frequency": 40
        },
        {
            "name": "LeftThigh",
            "color1": "Pink",
            "color2": "Black",
            "frequency": 40
        },
        {
            "name": "LeftLowerLeg",
            "color1": "Yellow",
            "color2": "Black",
            "frequency": 40
        },
        {
            "name": "Head",
            "color1": "Blue",
            "color2": "Black",
            "frequency": 40
        }
    ],
    "master_bone": "ChestBottom",
    "special": {
        "bone": "ChestBottom",
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
        },
        {
            "type": "INTERP",
            "target": "Neck",
            "source": "Head",
            "f": 0.5
        }
    ]
   "custom":{
        "config_name":"Full body + head"
    }
}
