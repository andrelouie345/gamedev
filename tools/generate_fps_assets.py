import json
import math
import random
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "models"


def _png(width, height, color, seed, pattern):
    rng = random.Random(seed)
    rows = bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            variation = rng.randint(-13, 13)
            if pattern == "wood":
                variation += int(9 * math.sin((y + x * 0.25) * 0.8))
            elif pattern == "fabric":
                variation += 7 if (x + y) % 4 == 0 else -2
            elif pattern == "paper":
                variation = rng.randint(-4, 4)
            rows.extend(max(0, min(255, channel + variation)) for channel in color)
            rows.append(255)
    def chunk(name, data):
        return (
            struct.pack(">I", len(data))
            + name
            + data
            + struct.pack(">I", zlib.crc32(name + data) & 0xFFFFFFFF)
        )
    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(
        b"IDAT", zlib.compress(bytes(rows), 9)
    ) + chunk(b"IEND", b"")


class Glb:
    def __init__(self):
        self.binary = bytearray()
        self.views = []
        self.accessors = []
        self.meshes = []
        self.nodes = []
        self.materials = []
        self.images = []
        self.textures = []
        self.samplers = []
        self.animations = []
        self._geometry = {}
        self._material = {}
        self.roots = []

    def _append(self, data, target=None):
        while len(self.binary) % 4:
            self.binary.append(0)
        offset = len(self.binary)
        self.binary.extend(data)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(data)}
        if target is not None:
            view["target"] = target
        self.views.append(view)
        return len(self.views) - 1

    def _accessor(self, values, kind, component, target=None, bounds=False):
        if component == 5126:
            data = struct.pack("<%sf" % len(values), *values)
        elif component == 5123:
            data = struct.pack("<%sH" % len(values), *values)
        else:
            raise ValueError("Unsupported accessor component")
        view = self._append(data, target)
        item_size = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[kind]
        result = {
            "bufferView": view,
            "componentType": component,
            "count": len(values) // item_size,
            "type": kind,
        }
        if bounds and kind == "VEC3":
            points = [values[i : i + 3] for i in range(0, len(values), 3)]
            result["min"] = [min(point[i] for point in points) for i in range(3)]
            result["max"] = [max(point[i] for point in points) for i in range(3)]
        if kind == "SCALAR" and component == 5126 and bounds:
            result["min"] = [min(values)]
            result["max"] = [max(values)]
        self.accessors.append(result)
        return len(self.accessors) - 1

    def material(self, name, color, roughness, metallic, pattern):
        if name in self._material:
            return self._material[name]
        image_bytes = _png(64, 64, color, len(self.materials) + 71, pattern)
        view = self._append(image_bytes)
        image = len(self.images)
        self.images.append(
            {"bufferView": view, "mimeType": "image/png", "name": name + "_texture"}
        )
        self.samplers = [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}]
        texture = len(self.textures)
        self.textures.append({"sampler": 0, "source": image, "name": name + "_texture"})
        index = len(self.materials)
        self.materials.append(
            {
                "name": name,
                "pbrMetallicRoughness": {
                    "baseColorTexture": {"index": texture},
                    "metallicFactor": metallic,
                    "roughnessFactor": roughness,
                },
            }
        )
        self._material[name] = index
        return index

    def mesh(self, name, vertices, normals, uvs, indices, material):
        positions = self._accessor(vertices, "VEC3", 5126, 34962, True)
        normal_accessor = self._accessor(normals, "VEC3", 5126, 34962)
        uv_accessor = self._accessor(uvs, "VEC2", 5126, 34962)
        index_accessor = self._accessor(indices, "SCALAR", 5123, 34963)
        index = len(self.meshes)
        self.meshes.append(
            {
                "name": name,
                "primitives": [
                    {
                        "attributes": {
                            "POSITION": positions,
                            "NORMAL": normal_accessor,
                            "TEXCOORD_0": uv_accessor,
                        },
                        "indices": index_accessor,
                        "material": material,
                    }
                ],
            }
        )
        return index

    def box(self, material, name="Box"):
        key = ("box", material)
        if key in self._geometry:
            return self._geometry[key]
        vertices, normals, uvs, indices = [], [], [], []
        faces = [
            ((1, 0, 0), ((.5, -.5, -.5), (.5, .5, -.5), (.5, .5, .5), (.5, -.5, .5))),
            ((-1, 0, 0), ((-.5, -.5, .5), (-.5, .5, .5), (-.5, .5, -.5), (-.5, -.5, -.5))),
            ((0, 1, 0), ((-.5, .5, -.5), (-.5, .5, .5), (.5, .5, .5), (.5, .5, -.5))),
            ((0, -1, 0), ((-.5, -.5, .5), (-.5, -.5, -.5), (.5, -.5, -.5), (.5, -.5, .5))),
            ((0, 0, 1), ((.5, -.5, .5), (.5, .5, .5), (-.5, .5, .5), (-.5, -.5, .5))),
            ((0, 0, -1), ((-.5, -.5, -.5), (-.5, .5, -.5), (.5, .5, -.5), (.5, -.5, -.5))),
        ]
        uv_face = ((0, 1), (0, 0), (1, 0), (1, 1))
        for normal, corners in faces:
            offset = len(vertices) // 3
            for corner, uv in zip(corners, uv_face):
                vertices.extend(corner)
                normals.extend(normal)
                uvs.extend(uv)
            indices.extend((offset, offset + 1, offset + 2, offset, offset + 2, offset + 3))
        mesh = self.mesh(name, vertices, normals, uvs, indices, material)
        self._geometry[key] = mesh
        return mesh

    def cylinder(self, material, name="Cylinder", segments=12):
        key = ("cylinder", material, segments)
        if key in self._geometry:
            return self._geometry[key]
        vertices, normals, uvs, indices = [], [], [], []
        for y in (-.5, .5):
            for index in range(segments):
                angle = math.tau * index / segments
                x, z = math.cos(angle) * .5, math.sin(angle) * .5
                vertices.extend((x, y, z))
                normals.extend((math.cos(angle), 0, math.sin(angle)))
                uvs.extend((index / segments, y + .5))
        for index in range(segments):
            nxt = (index + 1) % segments
            indices.extend((index, segments + index, segments + nxt,
                            index, segments + nxt, nxt))
        mesh = self.mesh(name, vertices, normals, uvs, indices, material)
        self._geometry[key] = mesh
        return mesh

    def sphere(self, material, name="Sphere", rings=6, segments=10):
        key = ("sphere", material, rings, segments)
        if key in self._geometry:
            return self._geometry[key]
        vertices, normals, uvs, indices = [], [], [], []
        for row in range(rings + 1):
            phi = math.pi * row / rings
            for col in range(segments + 1):
                theta = math.tau * col / segments
                normal = (
                    math.sin(phi) * math.cos(theta),
                    math.cos(phi),
                    math.sin(phi) * math.sin(theta),
                )
                vertices.extend(normal)
                normals.extend(normal)
                uvs.extend((col / segments, row / rings))
        for row in range(rings):
            for col in range(segments):
                a = row * (segments + 1) + col
                b = a + segments + 1
                indices.extend((a, a + 1, b, a + 1, b + 1, b))
        mesh = self.mesh(name, vertices, normals, uvs, indices, material)
        self._geometry[key] = mesh
        return mesh

    def disc(self, material, radius, name="Disc", segments=24):
        vertices = [0, 0, 0.0]
        normals = [0, 0, 1.0]
        uvs = [.5, .5]
        indices = []
        for index in range(segments):
            angle = math.tau * index / segments
            x, y = math.cos(angle), math.sin(angle)
            vertices.extend((x, y, 0))
            normals.extend((0, 0, 1))
            uvs.extend((x * .5 + .5, y * .5 + .5))
        for index in range(segments):
            indices.extend((0, index + 1, (index + 1) % segments + 1))
        return self.mesh(name, vertices, normals, uvs, indices, material)

    def node(self, name, mesh=None, parent=None, translation=(0, 0, 0), scale=(1, 1, 1), rotation=(0, 0, 0, 1)):
        node = {"name": name}
        if mesh is not None:
            node["mesh"] = mesh
        if translation != (0, 0, 0):
            node["translation"] = list(translation)
        if scale != (1, 1, 1):
            node["scale"] = list(scale)
        if rotation != (0, 0, 0, 1):
            node["rotation"] = list(rotation)
        node["_children"] = []
        index = len(self.nodes)
        self.nodes.append(node)
        if parent is None:
            self.roots.append(index)
        else:
            self.nodes[parent]["_children"].append(index)
        return index

    def add_box(self, parent, name, material, position, size, rotation=(0, 0, 0, 1)):
        return self.node(name, self.box(material, name), parent, position, size, rotation)

    def add_cylinder(self, parent, name, material, position, size, rotation=(0, 0, 0, 1)):
        return self.node(name, self.cylinder(material, name), parent, position, size, rotation)

    def add_sphere(self, parent, name, material, position, size):
        return self.node(name, self.sphere(material, name), parent, position, size)

    def animation(self, name, channels):
        samplers, animation_channels = [], []
        for node, path, times, values, kind in channels:
            input_accessor = self._accessor(times, "SCALAR", 5126, bounds=True)
            output_accessor = self._accessor(values, kind, 5126)
            sampler = len(samplers)
            samplers.append(
                {"input": input_accessor, "output": output_accessor, "interpolation": "LINEAR"}
            )
            animation_channels.append(
                {"sampler": sampler, "target": {"node": node, "path": path}}
            )
        self.animations.append(
            {"name": name, "samplers": samplers, "channels": animation_channels}
        )

    def save(self, filename):
        gltf_nodes = []
        for node in self.nodes:
            clean = {key: value for key, value in node.items() if key != "_children"}
            if node["_children"]:
                clean["children"] = node["_children"]
            gltf_nodes.append(clean)
        gltf = {
            "asset": {"version": "2.0", "generator": "Arena Shooter low-poly asset builder"},
            "scene": 0,
            "scenes": [{"nodes": self.roots}],
            "nodes": gltf_nodes,
            "meshes": self.meshes,
            "materials": self.materials,
            "textures": self.textures,
            "images": self.images,
            "samplers": self.samplers,
            "bufferViews": self.views,
            "accessors": self.accessors,
            "buffers": [{"byteLength": len(self.binary)}],
            "animations": self.animations,
        }
        json_bytes = json.dumps(gltf, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
        json_bytes += b" " * ((4 - len(json_bytes) % 4) % 4)
        binary = bytes(self.binary)
        binary += b"\x00" * ((4 - len(binary) % 4) % 4)
        total_length = 12 + 8 + len(json_bytes) + 8 + len(binary)
        glb = (
            struct.pack("<4sII", b"glTF", 2, total_length)
            + struct.pack("<I4s", len(json_bytes), b"JSON")
            + json_bytes
            + struct.pack("<I4s", len(binary), b"BIN\x00")
            + binary
        )
        (OUTPUT / filename).write_bytes(glb)


def _materials(model, names):
    definitions = {
        "metal": ("Blued steel", (63, 72, 76), .42, .78, "metal"),
        "dark_metal": ("Blackened steel", (37, 43, 46), .58, .62, "metal"),
        "wood": ("Oiled walnut", (111, 63, 37), .72, 0, "wood"),
        "wood_light": ("Worn walnut", (142, 87, 52), .76, 0, "wood"),
        "rubber": ("Rubber", (31, 35, 34), .86, 0, "fabric"),
        "sleeve": ("Olive uniform", (75, 86, 62), .96, 0, "fabric"),
        "glove": ("Tactical glove", (54, 59, 49), .94, 0, "fabric"),
        "trim": ("Glove reinforcement", (82, 83, 67), .88, 0, "fabric"),
        "paper": ("Target paper", (221, 218, 204), .98, 0, "paper"),
        "silhouette": ("Silhouette", (45, 54, 57), .94, 0, "fabric"),
        "target_red": ("Target red", (193, 52, 40), .88, 0, "paper"),
        "target_white": ("Target white", (241, 238, 221), .95, 0, "paper"),
        "stand": ("Target stand", (55, 62, 63), .8, .35, "metal"),
    }
    return {
        name: model.material(*definitions[name])
        for name in names
    }


def build_weapon():
    model = Glb()
    m = _materials(model, ("metal", "dark_metal", "wood", "wood_light",
                            "rubber", "sleeve", "glove", "trim"))
    view = model.node("Viewmodel")
    rifle = model.node("Rifle", parent=view)
    model.add_box(rifle, "Receiver", m["metal"], (0, 0, 0), (.19, .23, .49))
    model.add_box(rifle, "Receiver_cover", m["dark_metal"], (0, .135, -.01), (.17, .055, .39))
    model.add_box(rifle, "Stock_neck", m["wood"], (0, .015, .35), (.145, .15, .31))
    model.add_box(rifle, "Stock_butt", m["wood_light"], (0, .005, .62), (.19, .22, .26))
    model.add_box(rifle, "Stock_pad", m["rubber"], (0, 0, .765), (.195, .225, .045))
    model.add_box(rifle, "Handguard_lower", m["wood_light"], (0, -.02, -.39), (.2, .15, .35))
    model.add_box(rifle, "Handguard_upper", m["wood"], (0, .125, -.38), (.15, .075, .34))
    barrel_rot = (math.sin(math.pi / 4), 0, 0, math.cos(math.pi / 4))
    model.add_cylinder(rifle, "Barrel", m["metal"], (0, .015, -.7), (.072, .74, .072), barrel_rot)
    model.add_cylinder(rifle, "Muzzle", m["dark_metal"], (0, .015, -1.09), (.105, .11, .105), barrel_rot)
    model.add_cylinder(rifle, "Gas_tube", m["metal"], (0, .165, -.42), (.085, .43, .085), barrel_rot)
    model.add_box(rifle, "Front_sight", m["dark_metal"], (0, .22, -.92), (.035, .12, .035))
    model.add_box(rifle, "Rear_sight", m["dark_metal"], (0, .18, .16), (.065, .065, .07))
    model.add_box(rifle, "Rear_sight_notch", m["metal"], (0, .22, .16), (.018, .035, .075))
    model.add_box(rifle, "Pistol_grip", m["rubber"], (0, -.205, .205), (.12, .27, .16),
                  (math.sin(.13), 0, 0, math.cos(.13)))
    magazine_mesh = model.box(m["metal"], "Curved_magazine")
    magazine = model.node(
        "Magazine", magazine_mesh, rifle, (0, -.31, -.015), (.14, .43, .22)
    )
    model.add_box(rifle, "Magazine_floorplate", m["dark_metal"], (0, -.525, -.01), (.15, .035, .23))
    model.add_box(rifle, "Trigger_guard_top", m["metal"], (0, -.145, .12), (.12, .025, .14))
    model.add_box(rifle, "Trigger_guard_front", m["metal"], (0, -.185, .19), (.12, .07, .025))
    model.add_box(rifle, "Trigger_guard_rear", m["metal"], (0, -.185, .055), (.12, .07, .025))
    model.add_box(rifle, "Trigger", m["dark_metal"], (0, -.19, .125), (.018, .075, .018))
    model.add_box(rifle, "Safety_lever", m["dark_metal"], (.105, .015, .015), (.025, .08, .27))
    model.add_box(rifle, "Bolt_handle", m["metal"], (.11, .07, -.005), (.085, .07, .07))
    model.add_box(rifle, "Selector", m["dark_metal"], (.112, -.035, .18), (.028, .035, .14))
    model.add_box(rifle, "Handguard_rivet_left", m["metal"], (-.103, .0, -.42), (.012, .025, .045))
    model.add_box(rifle, "Handguard_rivet_right", m["metal"], (.103, .0, -.42), (.012, .025, .045))
    left_arm = model.node("Left_arm", parent=view)
    right_arm = model.node("Right_arm", parent=view)
    model.add_box(left_arm, "Left_sleeve", m["sleeve"], (-.275, -.305, -.08), (.21, .22, .59),
                  (0, 0, math.sin(-.16), math.cos(-.16)))
    model.add_box(left_arm, "Left_cuff", m["trim"], (-.205, -.218, -.265), (.22, .16, .105),
                  (0, 0, math.sin(-.16), math.cos(-.16)))
    model.add_box(left_arm, "Left_glove_palm", m["glove"], (-.145, -.105, -.37), (.19, .095, .2))
    model.add_box(left_arm, "Left_glove_thumb", m["glove"], (-.245, -.092, -.34), (.075, .08, .14),
                  (0, 0, math.sin(.35), math.cos(.35)))
    model.add_box(left_arm, "Left_glove_knuckle", m["trim"], (-.145, -.053, -.38), (.16, .02, .13))
    model.add_box(right_arm, "Right_sleeve", m["sleeve"], (.285, -.31, .12), (.22, .23, .49),
                  (0, 0, math.sin(.15), math.cos(.15)))
    model.add_box(right_arm, "Right_cuff", m["trim"], (.21, -.22, -.03), (.23, .16, .1))
    model.add_box(right_arm, "Right_glove_palm", m["glove"], (.115, -.13, .14), (.17, .1, .2))
    model.add_box(right_arm, "Right_glove_thumb", m["glove"], (.205, -.1, .19), (.075, .08, .14),
                  (0, 0, math.sin(-.4), math.cos(-.4)))
    for finger in range(3):
        model.add_box(right_arm, "Right_finger_%d" % finger, m["glove"],
                      (.055 + finger * .035, -.178, .12 + finger * .032), (.04, .055, .12))
    model.animation("Idle", [
        (view, "translation", [0, .8, 1.6], [0, 0, 0, 0, .008, 0, 0, 0, 0], "VEC3"),
    ])
    model.animation("Fire", [
        (rifle, "translation", [0, .06, .18], [0, 0, 0, 0, .012, .075, 0, 0, 0], "VEC3"),
        (rifle, "rotation", [0, .06, .18], [0, 0, 0, 1, .052, 0, 0, .999, 0, 0, 0, 1], "VEC4"),
        (right_arm, "translation", [0, .06, .18], [0, 0, 0, 0, 0, .035, 0, 0, 0], "VEC3"),
    ])
    model.animation("Reload", [
        (magazine, "translation", [0, .25, .75, 1.2, 1.55],
         [0, -.31, -.015, 0, -.45, .02, 0, -.45, .02, 0, -.31, -.015, 0, -.31, -.015], "VEC3"),
        (rifle, "rotation", [0, .25, .75, 1.2, 1.55],
         [0, 0, 0, 1, .035, 0, 0, .999, .035, 0, 0, .999, 0, 0, 0, 1, 0, 0, 0, 1], "VEC4"),
        (left_arm, "translation", [0, .25, .75, 1.2, 1.55],
         [0, 0, 0, .10, -.10, .16, .10, -.10, .16, 0, 0, 0, 0, 0, 0], "VEC3"),
    ])
    model.save("ak47_hands.glb")


def _target_support(model, m, root):
    stand = model.node("Support", parent=root)
    model.add_box(stand, "Pole", m["stand"], (0, -1.075, -.07), (.045, .78, .045))
    model.add_box(stand, "Foot", m["stand"], (0, -1.44, -.07), (.34, .05, .2))


def build_silhouette():
    model = Glb()
    m = _materials(model, ("paper", "silhouette", "target_red", "stand"))
    root = model.node("SilhouetteTarget")
    model.add_box(root, "Paper_backing", m["paper"], (0, 0, -.055), (.78, 1.48, .045))
    figure = model.node("Human_silhouette", parent=root)
    model.add_sphere(figure, "Head", m["silhouette"], (0, .48, .012), (.3, .32, .09))
    model.add_box(figure, "Neck", m["silhouette"], (0, .285, .012), (.14, .13, .08))
    model.add_box(figure, "Torso", m["silhouette"], (0, .035, .012), (.43, .48, .085))
    model.add_box(figure, "Shoulders", m["silhouette"], (0, .19, .012), (.62, .18, .08))
    model.add_box(figure, "Left_arm", m["silhouette"], (-.29, .045, .012), (.18, .49, .08),
                  (0, 0, math.sin(.12), math.cos(.12)))
    model.add_box(figure, "Right_arm", m["silhouette"], (.29, .045, .012), (.18, .49, .08),
                  (0, 0, math.sin(-.12), math.cos(-.12)))
    model.add_box(figure, "Left_leg", m["silhouette"], (-.12, -.39, .012), (.18, .43, .08),
                  (0, 0, math.sin(-.035), math.cos(-.035)))
    model.add_box(figure, "Right_leg", m["silhouette"], (.12, -.39, .012), (.18, .43, .08),
                  (0, 0, math.sin(.035), math.cos(.035)))
    model.add_sphere(root, "Head_aimpoint", m["target_red"], (0, .48, .062), (.075, .075, .012))
    model.add_box(root, "Chest_aimpoint", m["target_red"], (0, .12, .062), (.13, .14, .012))
    _target_support(model, m, root)
    model.save("target_silhouette.glb")


def build_bullseye():
    model = Glb()
    m = _materials(model, ("paper", "silhouette", "target_white", "target_red", "stand"))
    root = model.node("BullseyeTarget")
    model.add_box(root, "Paper_backing", m["paper"], (0, 0, -.055), (.82, 1.48, .045))
    model.add_box(root, "Black_target_field", m["silhouette"], (0, .08, -.02), (.63, .63, .025))
    center_y = .08
    for radius, material in ((.25, m["target_white"]), (.20, m["target_red"]),
                             (.15, m["target_white"]), (.10, m["target_red"]),
                             (.05, m["target_white"]), (.023, m["target_red"])):
        mesh = model.disc(material, radius, "Bullseye_ring")
        model.node("Ring_%02d" % round(radius * 100), mesh, root,
                   (0, center_y, .005 + (.25 - radius) * .001), (radius * 2, radius * 2, 1))
    model.add_box(root, "Top_label", m["stand"], (0, .57, .006), (.42, .055, .018))
    _target_support(model, m, root)
    model.save("target_bullseye.glb")


if __name__ == "__main__":
    OUTPUT.mkdir(parents=True, exist_ok=True)
    build_weapon()
    build_silhouette()
    build_bullseye()
    for asset in sorted(OUTPUT.glob("*.glb")):
        print("%s: %d bytes" % (asset.name, asset.stat().st_size))
