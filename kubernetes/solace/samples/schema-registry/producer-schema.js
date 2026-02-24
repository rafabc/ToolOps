const Ajv = require('ajv');
const addFormats = require('ajv-formats');
const solace = require('solclientjs');

// 1. Configuración
const REGISTRY_URL = 'http://localhost:8081/apis/registry/v3';
const GROUP_ID = 'default';
const SCHEMA_NAME = 'ORDER';
const SCHEMA_VERSION = '1.0.0';

// Credenciales según tu YAML
const USER = 'sr-developer';
const PASS = 'devPassword';

async function run() {
	let schema;

	// Crear el header de Basic Auth
	const authHeader = 'Basic ' + Buffer.from(`${USER}:${PASS}`).toString('base64');

	try {
		const url = `${REGISTRY_URL}/groups/${GROUP_ID}/artifacts/${SCHEMA_NAME}/versions/${SCHEMA_VERSION}/content`;
		console.log(`📡 Intentando descargar esquema con auth de: ${url}`);

		const response = await fetch(url, {
			headers: {
				'Authorization': authHeader,
				'Accept': 'application/json'
			}
		});

		if (!response.ok) {
			if (response.status === 401 || response.status === 403) {
				throw new Error("❌ Error de autenticación: Usuario o contraseña incorrectos en el Registry.");
			}
			if (response.status === 404) {
				console.warn(`\n⚠️  No se encontró el esquema '${SCHEMA_NAME}'. Listando disponibles...`);
				const searchRes = await fetch(`${REGISTRY_URL}/search/artifacts`, {
					headers: { 'Authorization': authHeader }
				});
				const searchData = await searchRes.json();
				console.dir(searchData.artifacts, { depth: null });
			}
			throw new Error(`Registry respondió con status: ${response.status}`);
		}

		const data = await response.json();

		// Manejo de la estructura del contenido
		schema = data.content ? (typeof data.content === 'string' ? JSON.parse(data.content) : data.content) : data;

		console.log('✅ Esquema cargado con éxito.');

	} catch (error) {
		console.error('❌ Fallo en la preparación:', error.message);
		return;
	}

	// 2. Preparar AJV
	const ajv = new Ajv({ allErrors: true, strict: true });
	console.log('🔍 Esquema a validar:', JSON.stringify(schema, null, 2));
	addFormats(ajv);
	console.log('🔍 Esquema compilado con AJV, listo para validar mensajes.');
	const validate = ajv.compile(schema);


	console.log('🔍 Validando mensaje de ejemplo contra el esquema...');

	// 3. Inicializar Solace
	solace.SolclientFactory.init({
		profile: solace.SolclientFactoryProfiles.version10
	});

	const session = solace.SolclientFactory.createSession({
		url: 'tcp://localhost:5555',
		vpnName: 'default',
		userName: 'admin', // Usuario del Broker (no del Registry)
		password: 'admin'
	});

	session.on(solace.SessionEventCode.UP_NOTICE, () => {
		const eventPayload = {
			owner: 'ORD-12345',
			amount: 125.50
		};

		if (!validate(eventPayload)) {
			console.error('❌ Datos inválidos:', validate.errors);
			session.disconnect();
			return;
		}

		const message = solace.SolclientFactory.createMessage();
		message.setDestination(solace.SolclientFactory.createTopic('orders/created'));
		message.setBinaryAttachment(Buffer.from(JSON.stringify(eventPayload)));
		message.setDeliveryMode(solace.MessageDeliveryModeType.PERSISTENT);

		// SDT Properties
		const userProps = new solace.SDTMapContainer();
		userProps.addField('schemaId', solace.SDTField.create(solace.SDTFieldType.STRING, `${SCHEMA_NAME}:${SCHEMA_VERSION}`));
		message.setUserPropertyMap(userProps);

		session.send(message);
		console.log('📤 Mensaje validado y enviado.');

		setTimeout(() => session.disconnect(), 1000);
	});

	session.on(solace.SessionEventCode.CONNECT_FAILED_ERROR, (e) => console.error('❌ Error Broker:', e.infoStr));
	session.on(solace.SessionEventCode.DISCONNECTED, () => process.exit(0));

	session.connect();
}

run();