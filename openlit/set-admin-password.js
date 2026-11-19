// Creates the OpenLIT admin (user@openlit.io) with OPENLIT_ADMIN_PASSWORD, or
// resets its password to that value. The upstream seed would otherwise create
// this account with a published default password.
const bcrypt = require("bcryptjs");
const { PrismaClient } = require("/app/client/node_modules/@prisma/client");

const EMAIL = "user@openlit.io";

(async () => {
  const pw = process.env.OPENLIT_ADMIN_PASSWORD;
  const prisma = new PrismaClient();
  try {
    const user = await prisma.user.findUnique({ where: { email: EMAIL }, select: { password: true } });
    if (user && user.password && bcrypt.compareSync(pw, user.password)) {
      console.log(`[openlit-railway] admin ${EMAIL} already uses OPENLIT_ADMIN_PASSWORD`);
      return;
    }
    const hash = bcrypt.hashSync(pw, 10);
    await prisma.user.upsert({
      where: { email: EMAIL },
      update: { password: hash },
      create: { email: EMAIL, password: hash, name: "Admin", hasCompletedOnboarding: true },
    });
    console.log(`[openlit-railway] admin ${EMAIL} ${user ? "password reset" : "created"} from OPENLIT_ADMIN_PASSWORD`);
  } finally {
    await prisma.$disconnect();
  }
})().catch((e) => {
  console.error(`[openlit-railway] admin bootstrap failed: ${e.message}`);
  process.exit(1);
});
