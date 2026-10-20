import { useId } from "react";
import type { FurnitureKind, Species } from "../game";

export function PetArt({
  species,
  color,
  accent,
  happy = false,
}: {
  species: Species;
  color: string;
  accent: string;
  happy?: boolean;
}) {
  return (
    <svg
      viewBox="0 0 120 140"
      fill="none"
      aria-hidden="true"
      className={`pet-art ${happy ? "pet-happy" : ""}`}
    >
      <ellipse cx="60" cy="130" rx="35" ry="6" fill="#655743" opacity=".13" />
      {species === "cat" && (
        <path
          className="pet-tail"
          d="M83 108C114 115 117 77 102 77"
          stroke={accent}
          strokeWidth="13"
          strokeLinecap="round"
        />
      )}
      {species === "dog" && (
        <path
          className="pet-tail"
          d="M84 108Q108 105 105 88"
          stroke={accent}
          strokeWidth="12"
          strokeLinecap="round"
        />
      )}
      {species === "bunny" && <circle cx="88" cy="106" r="11" fill="#fffaf1" />}
      <ellipse cx="60" cy="105" rx="29" ry="24" fill={color} />
      <ellipse cx="60" cy="110" rx="17" ry="17" fill="#fff7e8" opacity=".75" />
      <ellipse cx="43" cy="126" rx="12" ry="6" fill={color} />
      <ellipse cx="77" cy="126" rx="12" ry="6" fill={color} />
      {species === "cat" && (
        <>
          <path
            d="M27 61L28 28Q29 23 35 28L53 45M68 45L88 28Q94 24 94 31L94 65"
            fill={color}
            stroke={accent}
            strokeWidth="2"
          />
          <path d="M33 49L33 33L45 46M77 46L88 34L88 52" fill="#e9a4a0" />
        </>
      )}
      {species === "bunny" && (
        <>
          <ellipse
            cx="43"
            cy="35"
            rx="12"
            ry="30"
            transform="rotate(-12 43 35)"
            fill={color}
          />
          <ellipse
            cx="77"
            cy="35"
            rx="12"
            ry="30"
            transform="rotate(12 77 35)"
            fill={color}
          />
          <ellipse
            cx="43"
            cy="32"
            rx="5"
            ry="21"
            transform="rotate(-12 43 32)"
            fill={accent}
          />
          <ellipse
            cx="77"
            cy="32"
            rx="5"
            ry="21"
            transform="rotate(12 77 32)"
            fill={accent}
          />
        </>
      )}
      {species === "dog" && (
        <>
          <ellipse
            cx="30"
            cy="73"
            rx="15"
            ry="29"
            transform="rotate(13 30 73)"
            fill={accent}
          />
          <ellipse
            cx="91"
            cy="73"
            rx="15"
            ry="29"
            transform="rotate(-13 91 73)"
            fill={accent}
          />
        </>
      )}
      <rect x="27" y="45" width="66" height="58" rx="27" fill={color} />
      {species === "cat" && (
        <>
          <path
            d="M52 46L55 57M62 45V58M72 47L69 57"
            stroke={accent}
            strokeWidth="4"
            strokeLinecap="round"
          />
          <path
            d="M30 72L36 75M29 82L35 83M90 72L84 75M91 82L85 83"
            stroke={accent}
            strokeWidth="3"
            strokeLinecap="round"
          />
        </>
      )}
      {species === "dog" && (
        <ellipse cx="75" cy="64" rx="13" ry="16" fill={accent} opacity=".5" />
      )}
      <ellipse cx="60" cy="86" rx="19" ry="13" fill="#fff7e8" opacity=".85" />
      <g className="pet-eyes">
        {happy ? (
          <>
            <path
              d="M41 74Q46 68 51 74M69 74Q74 68 79 74"
              stroke="#493d37"
              strokeWidth="3"
              strokeLinecap="round"
            />
          </>
        ) : (
          <>
            <ellipse cx="46" cy="73" rx="3.4" ry="4.5" fill="#493d37" />
            <ellipse cx="74" cy="73" rx="3.4" ry="4.5" fill="#493d37" />
            <circle cx="47" cy="72" r="1" fill="white" />
            <circle cx="75" cy="72" r="1" fill="white" />
          </>
        )}
      </g>
      <ellipse cx="37" cy="83" rx="6" ry="3" fill="#e99f93" opacity=".65" />
      <ellipse cx="83" cy="83" rx="6" ry="3" fill="#e99f93" opacity=".65" />
      <path
        d="M56 82Q60 79 64 82L60 86Z"
        fill={species === "dog" ? "#655047" : "#c58782"}
      />
      <path
        d="M60 86V89M60 89Q56 94 52 90M60 89Q64 94 68 90"
        stroke="#6d5146"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
      {species === "cat" && (
        <path
          d="M36 87L20 84M36 91L21 93M84 87L100 84M84 91L99 93"
          stroke="#826b59"
          strokeWidth="1.3"
          strokeLinecap="round"
        />
      )}
      <path
        d="M40 103Q60 111 80 103"
        stroke={species === "cat" ? "#669582" : "#cd795c"}
        strokeWidth="5"
        strokeLinecap="round"
      />
      <circle cx="60" cy="108" r="4" fill="#e9bd62" />
      <circle cx="60" cy="108" r="1.5" fill="#a17c36" />
    </svg>
  );
}

export function FurnitureArt({ kind }: { kind: FurnitureKind }) {
  const id = useId().replace(/:/g, "");
  return (
    <svg
      viewBox={kind === "rug" ? "0 55 160 95" : "0 0 160 160"}
      fill="none"
      aria-hidden="true"
      className={`furniture-art art-${kind}`}
    >
      <defs>
        <pattern
          id={`weave${id}`}
          width="6"
          height="6"
          patternUnits="userSpaceOnUse"
        >
          <path d="M0 3H6M3 0V6" stroke="#805c3c" opacity=".13" />
        </pattern>
      </defs>
      {kind === "bed" && (
        <>
          <ellipse
            cx="80"
            cy="141"
            rx="68"
            ry="10"
            fill="#5c4c3e"
            opacity=".12"
          />
          <path
            d="M13 112Q12 79 37 78H124Q150 82 148 113L140 137Q80 157 21 136Z"
            fill="#bb885c"
          />
          <ellipse cx="80" cy="108" rx="65" ry="28" fill="#966845" />
          <ellipse cx="80" cy="110" rx="54" ry="22" fill="#ebc2ae" />
          <ellipse cx="80" cy="114" rx="43" ry="14" fill="#f2d5c4" />
          <path
            d="M17 115Q80 145 144 115"
            stroke="#d4a579"
            strokeWidth="9"
            strokeLinecap="round"
          />
          <path
            d="M25 128L29 140M41 134L43 145M60 139L61 148M80 140V150M100 138L99 148M120 133L118 144M136 127L132 138"
            stroke="#9b6e49"
            strokeWidth="2"
          />
        </>
      )}
      {kind === "plant" && (
        <>
          <ellipse
            cx="80"
            cy="145"
            rx="41"
            ry="8"
            fill="#5c4c3e"
            opacity=".12"
          />
          <path
            d="M80 114V32M78 90L53 63M81 77L107 44M79 61L60 32M83 99L115 79"
            stroke="#557b55"
            strokeWidth="4"
            strokeLinecap="round"
          />
          <ellipse
            cx="56"
            cy="58"
            rx="14"
            ry="26"
            transform="rotate(-42 56 58)"
            fill="#77956c"
          />
          <ellipse
            cx="107"
            cy="45"
            rx="14"
            ry="27"
            transform="rotate(38 107 45)"
            fill="#809d70"
          />
          <ellipse
            cx="65"
            cy="28"
            rx="13"
            ry="24"
            transform="rotate(-25 65 28)"
            fill="#a1b383"
          />
          <ellipse
            cx="113"
            cy="81"
            rx="14"
            ry="25"
            transform="rotate(55 113 81)"
            fill="#557f5f"
          />
          <ellipse cx="84" cy="26" rx="13" ry="23" fill="#67895d" />
          <path d="M50 107H110L103 141Q80 153 57 141Z" fill="#cb8d70" />
          <ellipse cx="80" cy="107" rx="32" ry="8" fill="#dfaa8a" />
          <ellipse cx="80" cy="107" rx="25" ry="4" fill="#795b41" />
          <path
            d="M61 118L64 140M73 119L74 144M87 119V144M100 118L97 140"
            stroke="#e2ad90"
            strokeWidth="2"
          />
        </>
      )}
      {kind === "scratch" && (
        <>
          <ellipse
            cx="80"
            cy="146"
            rx="57"
            ry="8"
            fill="#5c4c3e"
            opacity=".12"
          />
          <path d="M26 133Q80 122 135 133V143Q80 157 26 143Z" fill="#ae9270" />
          <ellipse cx="80" cy="133" rx="54" ry="11" fill="#c9b595" />
          <path d="M69 51H92V132Q81 141 69 132Z" fill="#cebb96" />
          <path
            d="M69 61L92 65M69 70L92 74M69 79L92 83M69 88L92 92M69 97L92 101M69 106L92 110M69 115L92 119M69 124L92 128"
            stroke="#aa9877"
            strokeWidth="2"
          />
          <path d="M35 40Q80 25 126 40V54Q80 68 35 54Z" fill="#8c9d89" />
          <ellipse cx="80" cy="39" rx="46" ry="12" fill="#abbba1" />
          <path d="M117 54V86" stroke="#a68e6a" strokeWidth="2" />
          <circle cx="117" cy="93" r="8" fill="#dfb96b" />
        </>
      )}
      {kind === "rug" && (
        <>
          <ellipse cx="80" cy="103" rx="76" ry="39" fill="#d9b775" />
          <ellipse
            cx="80"
            cy="103"
            rx="66"
            ry="32"
            stroke="#f0d5a1"
            strokeWidth="3"
          />
          <ellipse
            cx="80"
            cy="103"
            rx="57"
            ry="27"
            stroke="#b99b67"
            strokeWidth="1.5"
            strokeDasharray="3 4"
          />
          <ellipse
            cx="80"
            cy="103"
            rx="47"
            ry="22"
            stroke="#e9c98f"
            strokeWidth="2"
          />
          <path
            d="M80 82V124M38 103H122M51 88L109 118M51 118L109 88"
            stroke="#ebca8b"
            strokeWidth="2"
          />
          <ellipse cx="80" cy="103" rx="76" ry="39" fill={`url(#weave${id})`} />
        </>
      )}
      {kind === "bowl" && (
        <>
          <ellipse
            cx="80"
            cy="137"
            rx="69"
            ry="8"
            fill="#5c4c3e"
            opacity=".12"
          />
          <path d="M8 117H76L70 138Q43 148 15 138Z" fill="#9cafa0" />
          <ellipse cx="42" cy="117" rx="34" ry="11" fill="#c4d3bf" />
          <ellipse cx="42" cy="117" rx="25" ry="7" fill="#8d6746" />
          <path
            d="M25 116L31 113M37 120L43 114M49 117L55 112M60 118L54 121"
            stroke="#c19460"
            strokeWidth="4"
            strokeLinecap="round"
          />
          <path d="M83 117H151L145 138Q118 148 90 138Z" fill="#d8b3a0" />
          <ellipse cx="117" cy="117" rx="34" ry="11" fill="#efd4bf" />
          <ellipse cx="117" cy="117" rx="25" ry="7" fill="#92bdc4" />
          <path
            d="M104 116Q114 112 125 116"
            stroke="#d2eced"
            strokeWidth="2"
            strokeLinecap="round"
          />
        </>
      )}
      {kind === "cushion" && (
        <>
          <ellipse
            cx="80"
            cy="139"
            rx="59"
            ry="8"
            fill="#5c4c3e"
            opacity=".12"
          />
          <path
            d="M22 103Q13 80 44 90Q80 73 117 89Q145 78 137 104Q151 135 123 133Q80 150 39 134Q10 141 22 103Z"
            fill="#94a7b8"
          />
          <path
            d="M29 105Q31 90 51 97Q82 85 111 97Q131 91 131 106"
            stroke="#b8c9d3"
            strokeWidth="3"
          />
          <path
            d="M29 122Q80 145 131 122"
            stroke="#748fa4"
            strokeWidth="2"
            strokeDasharray="3 3"
          />
          <path
            d="M70 112Q80 105 90 112M70 117Q80 124 90 117"
            stroke="#7e9aaf"
            strokeWidth="2"
          />
        </>
      )}
      {kind === "lamp" && (
        <>
          <ellipse
            cx="80"
            cy="143"
            rx="38"
            ry="8"
            fill="#5c4c3e"
            opacity=".12"
          />
          <ellipse cx="80" cy="138" rx="29" ry="7" fill="#a27b53" />
          <path d="M80 46V136" stroke="#a27b53" strokeWidth="6" />
          <path d="M55 29H105L127 77Q80 91 33 77Z" fill="#f1dba5" />
          <ellipse cx="80" cy="77" rx="47" ry="9" fill="#d8bb80" />
          <ellipse cx="80" cy="77" rx="37" ry="5" fill="#ffedbf" />
          <path
            d="M63 31L52 77M80 30V80M97 31L108 77"
            stroke="#dfc78f"
            strokeWidth="2"
          />
          <path d="M113 82V103" stroke="#9c7948" strokeWidth="1.5" />
          <circle cx="113" cy="105" r="2.5" fill="#9c7948" />
        </>
      )}
      {kind === "toys" && (
        <>
          <ellipse
            cx="80"
            cy="142"
            rx="51"
            ry="7"
            fill="#5c4c3e"
            opacity=".12"
          />
          <circle cx="58" cy="99" r="22" fill="#cc8c76" />
          <path d="M37 99H79M58 77V121" stroke="#f0bba1" strokeWidth="4" />
          <path
            d="M85 106L105 70Q113 61 121 72L115 82L119 88Q118 100 107 94L96 115Z"
            fill="#c3d0b5"
          />
          <path d="M29 111H131L120 140Q80 151 40 140Z" fill="#c6a475" />
          <ellipse
            cx="80"
            cy="111"
            rx="51"
            ry="9"
            stroke="#b18d5e"
            strokeWidth="4"
          />
          <path
            d="M43 124H117M46 133H114M52 117L55 142M66 119V145M81 119V146M96 119L94 145M110 117L107 141"
            stroke="#ac895a"
            strokeWidth="2"
          />
        </>
      )}
    </svg>
  );
}

export function RoomBackdrop() {
  return (
    <svg
      viewBox="0 0 1000 620"
      preserveAspectRatio="none"
      className="room-backdrop"
      aria-hidden="true"
    >
      <defs>
        <linearGradient id="wall" x2="0" y2="1">
          <stop stopColor="#d8e0c9" />
          <stop offset="1" stopColor="#cbd6bc" />
        </linearGradient>
        <linearGradient id="floor" x2="0" y2="1">
          <stop stopColor="#dfbf91" />
          <stop offset="1" stopColor="#f1d4aa" />
        </linearGradient>
        <linearGradient id="sky" x2="0" y2="1">
          <stop stopColor="#b7d4da" />
          <stop offset="1" stopColor="#e2e9d3" />
        </linearGradient>
        <pattern
          id="wallpaper"
          width="38"
          height="38"
          patternUnits="userSpaceOnUse"
        >
          <path
            d="M19 14v10m-5-5h10"
            stroke="#8ba179"
            strokeWidth="1"
            opacity=".16"
          />
        </pattern>
        <pattern
          id="boards"
          width="200"
          height="57"
          patternUnits="userSpaceOnUse"
        >
          <path
            d="M0 0H200V57H0Z"
            stroke="#c8a77b"
            strokeWidth="1.4"
            fill="none"
          />
          <path
            d="M13 23q53-8 113 0m-90 8q54 5 96-1"
            stroke="#c29d70"
            strokeWidth="1"
            opacity=".23"
          />
        </pattern>
      </defs>
      <path fill="url(#wall)" d="M0 0H1000V320H0Z" />
      <path fill="url(#wallpaper)" d="M0 0H1000V320H0Z" />
      <path fill="url(#floor)" d="M0 315H1000V620H0Z" />
      <path fill="url(#boards)" d="M0 315H1000V620H0Z" />
      <path d="M0 305H1000V325H0Z" fill="#f2e7cf" />
      <path d="M0 325H1000" stroke="#b6ad8d" strokeWidth="3" />
      <path d="M106 259L204 259L455 620H224Z" fill="#fff3ca" opacity=".23" />
      <rect
        x="90"
        y="53"
        width="203"
        height="218"
        rx="72"
        fill="#a5b69a"
        opacity=".35"
      />
      <path
        d="M104 259V126A84 84 0 0 1 272 126V259Z"
        fill="url(#sky)"
        stroke="#f8f1df"
        strokeWidth="12"
      />
      <circle cx="235" cy="111" r="20" fill="#f8edb9" />
      <path
        d="M111 215Q151 170 190 211Q226 165 266 203V254H111Z"
        fill="#b3c39b"
      />
      <path
        d="M111 237Q159 209 195 235Q239 206 266 227V254H111Z"
        fill="#8da77c"
      />
      <path d="M188 49V256M105 158H270" stroke="#f8f1df" strokeWidth="9" />
      <path
        d="M87 261H289"
        stroke="#e8d8b7"
        strokeWidth="15"
        strokeLinecap="round"
      />
      <path
        d="M89 56Q69 147 83 245L103 247Q104 166 119 67M284 56Q308 145 294 245L274 247Q278 163 258 67"
        fill="#f6ead5"
      />
      <path
        d="M73 57H302"
        stroke="#ac936e"
        strokeWidth="6"
        strokeLinecap="round"
      />
      <rect x="429" y="89" width="108" height="123" rx="6" fill="#ac8c61" />
      <rect x="436" y="96" width="94" height="109" rx="2" fill="#f5e9ce" />
      <path d="M455 177Q477 138 513 176Z" fill="#a8b28a" />
      <circle cx="484" cy="136" r="16" fill="#e2b46d" />
      <path d="M447 188H520" stroke="#d0b996" strokeWidth="2" />
      <path d="M673 173H911V184H673Z" fill="#ae8c63" />
      <path d="M697 184V204M888 184V204" stroke="#94754f" strokeWidth="7" />
      <rect x="701" y="133" width="15" height="40" rx="2" fill="#b78b73" />
      <rect x="719" y="124" width="16" height="49" rx="2" fill="#b8c5b2" />
      <rect x="739" y="136" width="14" height="37" rx="2" fill="#dac58b" />
      <rect
        x="757"
        y="129"
        width="13"
        height="44"
        rx="2"
        fill="#a2afb0"
        transform="rotate(-9 757 129)"
      />
      <path
        d="M815 151Q803 129 818 116Q836 140 823 154M824 153Q828 125 845 129Q848 149 824 158"
        fill="#7d9b71"
      />
      <path d="M808 149H839L834 172H813Z" fill="#c38d73" />
      <path
        d="M864 144Q851 126 866 116Q876 132 872 148M872 149Q879 128 893 138Q890 151 873 153"
        fill="#a1b186"
      />
      <path d="M857 146H889L883 172H863Z" fill="#e3c994" />
      <path
        d="M360 0Q500 56 641 0"
        stroke="#a3ac89"
        strokeWidth="2"
        fill="none"
      />
      <path
        d="M379 9L385 31L396 15M423 23L432 44L443 28M475 31L486 52L497 31M529 29L542 47L551 25M578 16L594 31L600 10"
        fill="#d5ad7e"
      />
      <path d="M423 23L432 44L443 28M529 29L542 47L551 25" fill="#e3cba1" />
      <rect x="948" y="237" width="26" height="37" rx="4" fill="#e7e6d2" />
      <circle cx="957" cy="254" r="2" fill="#b7baa4" />
      <circle cx="965" cy="254" r="2" fill="#b7baa4" />
    </svg>
  );
}
