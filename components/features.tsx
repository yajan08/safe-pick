"use client";

import { motion, Variants } from "framer-motion";
import Link from "next/link";
import { 
  Shield, 
  Bell, 
  ChevronRight
} from "lucide-react";

const MapVisual = () => (
  <div className="absolute inset-0 bg-slate-50 dark:bg-zinc-950 overflow-hidden map-grid group-hover:scale-[1.03] transition-transform duration-1000 ease-out z-0">
    <svg className="absolute inset-0 w-full h-full" viewBox="0 0 400 300" preserveAspectRatio="xMidYMid slice">
      {/* Background orthogonal "streets" to make it look like a real map */}
      <path d="M 50,0 L 50,300 M 150,0 L 150,300 M 250,0 L 250,300 M 350,0 L 350,300" stroke="currentColor" className="text-foreground/10 dark:text-foreground/5" strokeWidth="12" />
      <path d="M 0,50 L 400,50 M 0,150 L 400,150 M 0,250 L 400,250" stroke="currentColor" className="text-foreground/10 dark:text-foreground/5" strokeWidth="12" />
      
      {/* The tracking route */}
      <motion.path
        d="M -20,250 L 50,250 L 50,150 L 250,150 L 250,50 L 450,50"
        fill="none"
        stroke="var(--foreground)"
        strokeWidth="5"
        strokeLinejoin="round"
        strokeLinecap="round"
        initial={{ pathLength: 0 }}
        whileInView={{ pathLength: 1 }}
        viewport={{ once: true }}
        transition={{ duration: 2, ease: "easeInOut" }}
        style={{ filter: "drop-shadow(0px 8px 12px rgba(0,0,0,0.15))" }}
      />
      <motion.circle 
         r="7" 
         fill="#22c55e"
         className="shadow-[0_0_10px_rgba(34,197,94,0.8)]"
         animate={{ offsetDistance: ["0%", "100%"] }}
         style={{ 
           offsetPath: "path('M -20,250 L 50,250 L 50,150 L 250,150 L 250,50 L 450,50')",
           offsetRotate: "auto" 
         } as any}
         transition={{ duration: 6, repeat: Infinity, ease: "linear" }}
      />
      <motion.circle 
         r="16" 
         fill="rgba(34,197,94,0.15)"
         stroke="#22c55e"
         strokeWidth="2"
         animate={{ offsetDistance: ["0%", "100%"], scale: [1, 1.8, 1], opacity: [1, 0, 1] }}
         style={{ offsetPath: "path('M -20,250 L 50,250 L 50,150 L 250,150 L 250,50 L 450,50')" } as any}
         transition={{ duration: 6, repeat: Infinity, ease: "linear" }}
      />
    </svg>
    <div className="absolute top-4 right-4 bg-background rounded-xl p-2 flex items-center gap-2 shadow-md border border-border group-hover:-translate-y-1.5 transition-transform duration-500">
       <div className="w-8 h-8 rounded-lg bg-gold flex items-center justify-center">
          <span className="text-xs font-black text-foreground">MH12</span>
       </div>
       <div className="pr-2">
         <div className="text-[11px] font-bold text-foreground leading-tight">Tracking Rahul</div>
         <div className="text-[9px] font-semibold text-green-600 flex items-center gap-1 mt-0.5">
           <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse" />
           On Schedule
         </div>
       </div>
    </div>
  </div>
);

const QRVisual = () => (
  <div className="absolute inset-0 flex items-center justify-center overflow-hidden">
    <div className="relative w-24 h-24 bg-background rounded-xl border-[3px] border-foreground shadow-[4px_4px_0px_0px_rgba(0,0,0,0.15)] p-2 group-hover:scale-110 transition-transform duration-500 flex flex-col justify-between">
      {/* Three corner squares of QR */}
      <div className="flex justify-between w-full">
         <div className="w-6 h-6 border-[3px] border-foreground p-0.5"><div className="w-full h-full bg-foreground" /></div>
         <div className="w-6 h-6 border-[3px] border-foreground p-0.5"><div className="w-full h-full bg-foreground" /></div>
      </div>
      {/* Some random dots */}
      <div className="w-full flex justify-center gap-1.5">
         <div className="w-2 h-2 bg-foreground" />
         <div className="w-2 h-2 bg-foreground" />
         <div className="w-2 h-2 bg-foreground" />
         <div className="w-2 h-2 bg-foreground" />
      </div>
      <div className="flex justify-between w-full">
         <div className="w-6 h-6 border-[3px] border-foreground p-0.5"><div className="w-full h-full bg-foreground" /></div>
         <div className="w-6 h-6 flex flex-wrap gap-1">
            <div className="w-2 h-2 bg-foreground" />
            <div className="w-2 h-2 bg-foreground" />
            <div className="w-2 h-2 bg-foreground" />
            <div className="w-2 h-2 bg-foreground" />
         </div>
      </div>
      
      <motion.div 
        className="absolute left-0 right-0 h-0.5 bg-red-500 shadow-[0_0_12px_rgba(239,68,68,1)]"
        animate={{ top: ["5%", "95%", "5%"] }}
        transition={{ duration: 2.5, repeat: Infinity, ease: "linear" }}
      />
    </div>
  </div>
);

const AlertsVisual = () => (
  <div className="absolute inset-0 flex items-center justify-center overflow-hidden">
    <div className="relative group-hover:scale-110 transition-transform duration-500">
      <motion.div
        animate={{ rotate: [0, -12, 12, -12, 12, 0] }}
        transition={{ duration: 1, repeat: Infinity, repeatDelay: 2 }}
        className="relative z-10 bg-gold p-4 rounded-[1.5rem] shadow-[3px_3px_0px_0px_rgba(255,255,255,0.2)] border-2 border-background"
      >
        <Bell className="w-8 h-8 text-foreground" />
        <motion.div 
          className="absolute top-2.5 right-2.5 w-3 h-3 bg-red-500 rounded-full border-[2px] border-gold"
          initial={{ scale: 0 }}
          animate={{ scale: [0, 1.3, 1] }}
          transition={{ duration: 0.5, repeat: Infinity, repeatDelay: 3 }}
        />
      </motion.div>
      <motion.div
        className="absolute inset-0 border-2 border-gold rounded-[1.5rem]"
        initial={{ scale: 1, opacity: 0 }}
        animate={{ scale: 1.5, opacity: [0, 0.4, 0] }}
        transition={{ duration: 2, repeat: Infinity }}
      />
    </div>
  </div>
);

const SecurityVisual = () => (
  <div className="absolute inset-0 bg-slate-50 dark:bg-zinc-900/40 flex items-center justify-center overflow-hidden">
    <div className="relative group-hover:scale-110 transition-transform duration-500">
      <div className="bg-background p-4 rounded-[1.5rem] border-2 border-border shadow-[3px_3px_0px_0px_rgba(0,0,0,0.05)] relative z-10">
        <Shield className="w-8 h-8 text-foreground" />
      </div>
      <motion.div
        className="absolute inset-0 bg-gold blur-[20px] z-0 rounded-full"
        animate={{ opacity: [0.1, 0.4, 0.1], scale: [0.8, 1.4, 0.8] }}
        transition={{ duration: 3, repeat: Infinity }}
      />
    </div>
  </div>
);

const EcosystemVisual = () => (
  <div className="absolute inset-0 bg-slate-50 dark:bg-zinc-900/40 flex items-center justify-center gap-4 sm:gap-6 overflow-hidden group-hover:bg-slate-100 dark:group-hover:bg-zinc-900/60 transition-colors duration-500">
    <motion.div 
      className="w-16 h-28 bg-background border-2 border-foreground rounded-xl shadow-sm relative p-2 overflow-hidden z-20 group-hover:-translate-y-2 transition-transform duration-500"
    >
      <div className="w-full h-1 bg-border rounded-full mb-2 mx-auto max-w-[24px]" />
      <div className="space-y-1.5">
        <div className="w-full h-3 bg-gold/30 rounded-sm" />
        <div className="w-2/3 h-2 bg-border/50 rounded-sm" />
        <div className="w-full h-8 bg-slate-100 dark:bg-zinc-800 rounded-sm mt-3" />
      </div>
    </motion.div>
    
    <motion.div 
      className="flex gap-2 text-gold z-10 opacity-50 group-hover:opacity-100 transition-opacity"
      animate={{ scale: [0.9, 1.1, 0.9] }}
      transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
    >
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
        <path d="M17 1l4 4-4 4" />
        <path d="M3 11V9a4 4 0 0 1 4-4h14" />
        <path d="M7 23l-4-4 4-4" />
        <path d="M21 13v2a4 4 0 0 1-4 4H3" />
      </svg>
    </motion.div>

    <motion.div 
      className="w-24 h-16 bg-background border-2 border-foreground rounded-lg shadow-sm p-2 z-20 flex flex-col group-hover:translate-y-2 transition-transform duration-500"
    >
      <div className="flex gap-1 mb-1.5 border-b border-border pb-1">
        <div className="w-1.5 h-1.5 rounded-full bg-red-400" />
        <div className="w-1.5 h-1.5 rounded-full bg-yellow-400" />
        <div className="w-1.5 h-1.5 rounded-full bg-green-400" />
      </div>
      <div className="flex gap-1.5 flex-1">
        <div className="w-1/3 h-full bg-border/40 rounded-sm" />
        <div className="w-2/3 h-full bg-gold/20 rounded-sm" />
      </div>
    </motion.div>
  </div>
);

const features = [
  {
    title: "Live Tracking",
    description: "Track every van with 5-meter precision. Our AI dynamically optimizes routes based on live traffic patterns.",
    className: "md:col-span-2 md:row-span-2",
    Visual: MapVisual,
    isFullBleed: true,
    bgClass: "bg-card text-foreground",
    descClass: "text-muted-foreground",
  },
  {
    title: "QR Scanning",
    description: "Each student entry and exit happens via secure QR scanning, ensuring fail-proof pickup and drop-off.",
    className: "md:col-span-1 md:row-span-1",
    Visual: QRVisual,
    bgClass: "bg-gold text-foreground",
    descClass: "text-foreground/80",
  },
  {
    title: "Instant Alerts & Notifications",
    description: "Real-time push notifications when students arrive at school or return safely home.",
    className: "md:col-span-1 md:row-span-1",
    Visual: AlertsVisual,
    bgClass: "bg-foreground text-background",
    descClass: "text-background/80",
  },
  {
    title: "Secure System",
    description: "No outsiders can see your location. We use MQTT and end-to-end encryption for absolute privacy.",
    className: "md:col-span-1 md:row-span-1",
    Visual: SecurityVisual,
    bgClass: "bg-card text-foreground",
    descClass: "text-muted-foreground",
  },
  {
    title: "Attendance History",
    description: "Detailed daily attendance records. Making school transport safer and transparent for parents and drivers.",
    className: "md:col-span-2 md:row-span-1",
    Visual: EcosystemVisual,
    isHorizontal: true,
    bgClass: "bg-card text-foreground",
    descClass: "text-muted-foreground",
  },
];

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1 },
  },
};

const itemVariants: Variants = {
  hidden: { opacity: 0, y: 15 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4, ease: "easeOut" },
  },
};

export function Features() {
  return (
    <section className="relative z-30 py-20 sm:py-28 px-4 sm:px-6 bg-background transition-colors duration-300">
      <div className="max-w-7xl mx-auto relative z-10">
        
        {/* Header Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="mb-12 sm:mb-20 flex flex-col md:flex-row md:items-end justify-between gap-8"
        >
          <div className="max-w-3xl">
            <h2 className="text-4xl sm:text-5xl md:text-6xl font-heading font-black tracking-tight text-foreground leading-tight text-balance">
              Complete Peace of Mind <br className="hidden md:block"/>
              <span className="text-gold font-bold">for Your Child's Commute.</span>
            </h2>
            <div className="mt-5">
              <p className="text-muted-foreground text-base sm:text-lg font-medium leading-relaxed max-w-2xl">
                Our mission is to build a reliable and trusted platform that ensures safer and hassle-free school commutes for children, with better transparency for parents and drivers.
              </p>
            </div>
          </div>
          
          <div className="hidden lg:block shrink-0 pb-2">
             <Link href="/demo">
                <motion.button
                  className="group inline-flex items-center justify-center gap-2 bg-foreground text-background font-bold uppercase tracking-wider px-6 py-3.5 rounded-full transition-all hover:bg-gold hover:text-foreground hover:shadow-lg hover:-translate-y-1 text-sm font-heading"
                >
                  Explore the Platform
                  <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                </motion.button>
              </Link>
          </div>
        </motion.div>

        {/* Neo-Bento Grid */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          className="grid grid-cols-1 md:grid-cols-3 gap-4 sm:gap-5"
        >
          {features.map((feature, index) => {
            const isFullBleed = feature.isFullBleed;

            return (
              <motion.div
                key={index}
                variants={itemVariants}
                className={`group relative flex flex-col border border-border/80 rounded-3xl overflow-hidden transition-all duration-300 shadow-sm hover:shadow-xl hover:-translate-y-1 ${feature.className} ${feature.bgClass} ${feature.isHorizontal ? 'md:flex-row' : ''}`}
              >
                {/* Visual Section */}
                <div className={`relative w-full ${isFullBleed ? 'absolute inset-0 h-full z-0' : feature.isHorizontal ? 'h-40 md:h-auto md:w-1/2 md:order-last' : 'h-40 sm:h-48'}`}>
                   <feature.Visual />
                </div>

                {/* Content Section */}
                {isFullBleed ? (
                  <div className="absolute bottom-4 left-4 right-4 sm:bottom-6 sm:left-6 sm:right-6 p-5 sm:p-6 bg-background/90 backdrop-blur-md border border-border/50 rounded-2xl z-10 shadow-sm">
                     <h3 className="text-xl sm:text-2xl font-heading font-bold tracking-tight mb-2 text-foreground">{feature.title}</h3>
                     <p className="text-sm sm:text-base leading-relaxed text-muted-foreground">{feature.description}</p>
                  </div>
                ) : (
                  <div className={`relative p-6 sm:p-7 flex flex-col justify-end z-10 flex-1 ${feature.isHorizontal ? 'md:w-1/2' : ''}`}>
                     <h3 className="text-xl sm:text-2xl font-heading font-bold tracking-tight mb-2">{feature.title}</h3>
                     <p className={`text-sm sm:text-base leading-relaxed max-w-sm ${feature.descClass}`}>{feature.description}</p>
                  </div>
                )}
              </motion.div>
            );
          })}
        </motion.div>

        {/* Mobile CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2 }}
          className="mt-8 block lg:hidden"
        >
          <Link href="/demo">
            <button className="w-full inline-flex items-center justify-center gap-2 bg-foreground text-background font-bold uppercase tracking-wider px-6 py-4 rounded-xl hover:bg-gold hover:text-foreground transition-colors text-sm font-heading">
              Explore the Platform
              <ChevronRight className="w-4 h-4" />
            </button>
          </Link>
        </motion.div>
      </div>
    </section>
  );
}

