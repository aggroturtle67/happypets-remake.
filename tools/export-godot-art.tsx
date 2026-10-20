// One-time source artwork conversion. Godot itself does not require Node or React.
import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { writeFileSync } from "node:fs";
import { PetArt, FurnitureArt, RoomBackdrop } from "../src/components/Art";
import { DECOR, PETS } from "../src/game";

function save(name: string, node: React.ReactNode, width: number, height: number) {
  let svg = renderToStaticMarkup(node);
  svg = svg.replace("<svg ", `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" `);
  writeFileSync(new URL(`../godot/assets/${name}.svg`, import.meta.url), svg);
}
save("room", <RoomBackdrop />, 1000, 620);
save("cat", <PetArt species="cat" color="#e8ae70" accent="#c68c51" />, 120, 140);
save("dog", <PetArt species="dog" color="#e5d0b2" accent="#9f765b" />, 120, 140);
for (const pet of PETS) save(pet.id, <PetArt {...pet} />, 120, 140);
for (const item of DECOR) save(item.kind, <FurnitureArt kind={item.kind} />, 160, item.kind === "rug" ? 95 : 160);
