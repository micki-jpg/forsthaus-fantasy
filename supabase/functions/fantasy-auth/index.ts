import { createClient } from "npm:@supabase/supabase-js@2.57.4";
const url = Deno.env.get("SUPABASE_URL")!;
const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, { auth: { persistSession: false, autoRefreshToken: false } });
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info", "Access-Control-Allow-Methods": "POST, OPTIONS" };
const reply = (data: unknown, status=200) => new Response(JSON.stringify(data), {status,headers:{...cors,"Content-Type":"application/json","Cache-Control":"no-store"}});
const digest = async (text:string) => Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(text)))).map(x=>x.toString(16).padStart(2,"0")).join("");
Deno.serve(async req => {
 if(req.method === "OPTIONS") return new Response(null,{headers:cors});
 if(req.method !== "POST") return reply({error:"Nur POST erlaubt."},405);
 try {
  const body=await req.text();if(body.length>8192)return reply({error:"Anfrage zu groß."},413);
  const input=JSON.parse(body), login=String(input.login||"").trim().toLowerCase(), password=String(input.password||"");
  if(input.action === "reset") {
   const token=String(input.token||"");
   if(!/^[a-f0-9]{64}$/.test(token)||password.length<10||password.length>128)return reply({error:"Reset-Link oder Passwort ungültig."},400);
   const {data:userId,error}=await admin.rpc("fantasy_consume_reset",{p_hash:await digest(token)});
   if(error||!userId)return reply({error:"Reset-Link ungültig, verbraucht oder abgelaufen."},400);
   const {error:updateError}=await admin.auth.admin.updateUserById(userId,{password});
   if(updateError)return reply({error:"Passwort konnte nicht gespeichert werden. Bitte den Admin um einen neuen Reset-Link bitten."},500);
   return reply({reset:true});
  }
  if(!/^[a-z0-9_]{3,24}$/.test(login)||password.length<10||password.length>128)return reply({error:"Login: 3–24 Zeichen (a–z, 0–9, _). Passwort: 10–128 Zeichen."},400);
  // Interne technische Adresse, keine persönliche E-Mail und kein Mailversand.
  const loginHash=await digest(login);
  const {data:allowed,error:limitError}=await admin.rpc("fantasy_auth_attempt",{p_key:loginHash});
  if(limitError||!allowed)return reply({error:"Zu viele Versuche. Bitte in 15 Minuten erneut versuchen."},429);
  const email=`${loginHash}@accounts.forsthaus.invalid`;
  const client=createClient(url,Deno.env.get("SUPABASE_ANON_KEY")!,{auth:{persistSession:false,autoRefreshToken:false}});
  if(input.action === "register") {
   const token=String(input.token||""),name=String(input.name||"").trim();
   if(!/^[a-f0-9]{64}$/.test(token)||!name||name.length>32)return reply({error:"Einladung oder Anzeigename ungültig."},400);
   const hash=await digest(token);
   const {data:invite,error:lookup}=await admin.from("fantasy_invites").select("slot,expires_at,used_at,purpose").eq("token_hash",hash).maybeSingle();
   if(lookup||!invite||invite.purpose!=="invite"||invite.used_at||Date.parse(invite.expires_at)<=Date.now())return reply({error:"Einladung ungültig, verbraucht oder abgelaufen."},400);
   const {data:created,error}=await admin.auth.admin.createUser({email,password,email_confirm:true});
   if(error||!created.user)return reply({error:"Login-Name nicht verfügbar oder Registrierung fehlgeschlagen."},400);
   const {error:redeem}=await admin.rpc("fantasy_redeem_invite",{p_hash:hash,p_user:created.user.id,p_login:login,p_name:name});
   if(redeem){await admin.auth.admin.deleteUser(created.user.id);return reply({error:"Einladung bereits verwendet oder Registrierung fehlgeschlagen."},409);}
  } else if(input.action !== "login") return reply({error:"Ungültige Aktion."},400);
  const {data,error}=await client.auth.signInWithPassword({email,password});
  if(error||!data.session)return reply({error:"Login-Name oder Passwort stimmt nicht."},401);
  const {data:member}=await admin.from("fantasy_members").select("slot,name,role").eq("user_id",data.user.id).maybeSingle();
  if(!member)return reply({error:"Kein Liga-Zugang zugeordnet."},403);
  return reply({session:data.session,member});
 } catch {return reply({error:"Anfrage konnte nicht verarbeitet werden."},400);}
});
