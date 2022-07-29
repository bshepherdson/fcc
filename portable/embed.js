const inputfile = process.argv[2];
const outputfile = process.argv[3];
const barefile = inputfile.split("/").pop();
const basename = "_core_" + barefile.split(".")[0];

const {section, type_tag} = require("os").platform() === "darwin" ?
  {section: "__TEXT,__const", type_tag: "#"} :
  {section: ".rodata", type_tag: ".type"};

const contents = `
    .section    ${section}
    .global     ${basename}_start
    ${type_tag} ${basename}_start, @object
    .align      4
${basename}_start:
    .incbin "${inputfile}"
${basename}_end:
    .global     ${basename}_end
    ${type_tag} ${basename}_end, @object
`;

require("fs").writeFileSync(outputfile, contents);
