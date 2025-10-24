import React from "react";
import { BookOpenText } from "lucide-react";

const HowToBanner: React.FC = () => (
  <div
    className="
      w-full flex items-center gap-6
      bg-gradient-to-br from-black/80 via-emerald-950/40 to-black/80
      rounded-xl shadow-xl relative px-5 pt-5 pb-4 mb-7 border border-emerald-500/20
      "
    style={{
      boxShadow:
        "0 2px 20px 0 rgba(34,197,94,0.12), 0 1.5px 14px 0 rgba(16,185,129,0.15)",
    }}
  >
    {/* Logo image */}
    <div className="flex-shrink-0">
      <img
        src="https://iili.io/KgkdS1f.png"
        alt="TipNtop Club Logo"
        className="w-20 h-20 md:w-24 md:h-24 rounded-lg object-cover shadow border-2 border-emerald-500/20 bg-black/60"
        loading="lazy"
      />
    </div>
    {/* Content */}
    <div className="flex-1 flex flex-col">
      <div className="flex items-center gap-2 mb-0.5">
        <BookOpenText className="h-6 w-6 text-emerald-400" />
        <h1 className="text-2xl font-heading font-bold text-white tracking-tight">
          Welcome to{" "}
          <span
            className="gradient-text font-heading font-bold"
            style={{
              background:
                "linear-gradient(90deg, #10b981 0%, #059669 100%)",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent",
              display: "inline-block",
            }}
          >
            TipNtop Club
          </span>
          !
        </h1>
      </div>
      <p className="text-base md:text-lg font-quicksand text-white/85 mt-0.5 leading-normal">
        Manage your snooker club, staff, members, and tables{" "}
        <span
          className="gradient-text font-heading font-bold"
          style={{
            background:
              "linear-gradient(90deg, #10b981 0%, #059669 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            display: "inline-block",
          }}
        >
          efficiently
        </span>
        .<br />
        <span className="text-white/75">
          This interactive guide unlocks every feature for your workflow.
        </span>
        <br />
        <span className="text-emerald-400 font-semibold">Tip:</span>
        <span className="ml-1 text-white/75">
          Click any section below for pro tips!
        </span>
      </p>
    </div>
  </div>
);

export default HowToBanner;
