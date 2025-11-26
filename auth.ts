import NextAuth from "next-auth";
import CredentialsProvider from "next-auth/providers/credentials";
import { PrismaAdapter } from "@next-auth/prisma-adapter";
import { prisma } from "@/lib/prisma";
import { JWT } from "next-auth/jwt";
import { Session } from "next-auth";
import bcrypt from "bcryptjs";


export const authOptions = {
  adapter: PrismaAdapter(prisma),
  session: {
    strategy: "jwt" as const,
  },
  pages: {
    signIn: "/login",
    error: "/login",
  },
  secret : process.env.NEXTAUTH_SECRET,
  providers: [
    CredentialsProvider({
      name: "Credentials",
      credentials: {
        username: { label: "Usuario", type: "text" },
        password: { label: "Contraseña", type: "password" },
      },
      async authorize(credentials) {
        const user = await prisma.users.findUnique({
          where: { username: credentials?.username },
          select: {
            id: true,
            username: true,
            email: true,
            password: true,
            role: true,
            first_name: true,
            last_name: true,
            phone: true,
            avatar_url: true,
            created_at: true,
          }
        });

        if (
          user &&
          (await bcrypt.compare(credentials!.password, user.password))
        ) {
          return {
            id: String(user.id),
            name: user.username,
            email: user.email || user.username, // Usar email si existe, sino username
            role: user.role,
            first_name: user.first_name,
            last_name: user.last_name,
            phone: user.phone,
            avatar_url: user.avatar_url,
            created_at: user.created_at?.toISOString(),
          };
        }
        return null;
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }: { token: JWT; user?: any }) {
      if (user) {
        token.id = user.id;
        token.role = user.role;
        token.email = user.email;
      }
      return token;
    },
    async session({ session, token }: { session: Session; token: JWT }) {
      if (token) {
        session.user.id = token.id;
        session.user.role = token.role;
        session.user.email = token.email || session.user.email;
      }
      return session;
    },
  },
};

const handler = NextAuth(authOptions);
export { handler as GET, handler as POST };
