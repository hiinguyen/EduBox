import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import { createHocTapWorld, type HocTapWorld } from "@/test/hoc-tap-world";
import { MATERIAL_LIMIT } from "./constants";
import { loadMaterials } from "./catalog";

let world: HocTapWorld;
let chemistryId: string;

const base = { kind: "Đề", detail: "d", icon: "quiz", tone: "PRIMARY", footnote: "f" } as const;

beforeAll(async () => {
  world = await createHocTapWorld();
  // More recommended maths items than the list holds, so a first-page-only filter would hide chemistry.
  await db.material.createMany({
    data: Array.from({ length: MATERIAL_LIMIT + 1 }, (_, index) => ({
      ...base,
      subject: "MATH" as const,
      title: `math-${index}-${world.tag}`,
      isRecommended: true,
    })),
  });
  const chemistry = await db.material.create({
    data: { ...base, subject: "CHEMISTRY", title: `chem-${world.tag}`, isRecommended: false },
    select: { id: true },
  });
  chemistryId = chemistry.id;
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

describe("loadMaterials", () => {
  it("keeps a subject chip even when its materials do not fit in the bounded list", async () => {
    const all = await loadMaterials("all");

    expect(all.materials.length).toBeLessThanOrEqual(MATERIAL_LIMIT);
    expect(all.materials.map((material) => material.id)).not.toContain(chemistryId);
    expect(all.filters.map((option) => option.value)).toContain("chemistry");
  });

  it("filters on the server so the hidden subject's materials appear", async () => {
    const chemistry = await loadMaterials("chemistry");

    expect(chemistry.materials.map((material) => material.id)).toContain(chemistryId);
    expect(chemistry.materials.every((material) => material.subject === "chemistry")).toBe(true);
  });

  it("returns only the chosen subject and stays bounded", async () => {
    const math = await loadMaterials("math");

    expect(math.materials.length).toBe(MATERIAL_LIMIT);
    expect(math.materials.every((material) => material.subject === "math")).toBe(true);
  });

  it("returns an empty list for a subject without materials but keeps the chips", async () => {
    await db.material.deleteMany({ where: { subject: "PHYSICS", title: { contains: world.tag } } });

    const physics = await loadMaterials("physics");

    expect(physics.materials.filter((material) => material.title.includes(world.tag))).toEqual([]);
    expect(physics.filters.map((option) => option.value)).toContain("math");
  });
});
