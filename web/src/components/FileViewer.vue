<template>
	<v-container fluid>
		<portal to="navbar">
			<v-toolbar-items>
				<v-icon>mdi-menu-right</v-icon>
				<v-label>{{ title }}</v-label
				>
			</v-toolbar-items>
		</portal>
		<FileUploadDialog
			v-model="showUploadDialog"
			:uploadUrl="uploadUrl"
			@uploaded="uploadComplete"
		/>
		<v-row justify="center" v-if="uploadEnabled">
			<v-col md="8" lg="6" class="pt-0 pb-0">
				<v-btn
					v-text="$t('upload')"
					color="primary"
					@click="showUploadDialog = true"
				></v-btn>
			</v-col>
		</v-row>
		<v-row justify="center">
			<v-col md="8" lg="6">
				<v-card
					class="mx-auto"
					tile
					:loading="loading"
				>
					<v-list-item
						v-for="item in list"
						:key="item.id"
						class="pl-0"
						tag="a"
						:href="getFileUrl(item)"
						@click.stop
					>
						<v-list-item-avatar class="ma-0">
							<v-icon>{{ item.icon }}</v-icon>
						</v-list-item-avatar>
						<v-list-item-content class="py-2">
							<v-list-item-title
								v-text="item.isParent ? '..' : item.fileName"
							></v-list-item-title>
							<v-list-item-subtitle
								v-if="!item.isFolder"
								v-text="item.fileSize"
							></v-list-item-subtitle>
						</v-list-item-content>
						<v-list-item-action v-if="!item.isFolder && !item.isGoogleFile">
							<v-btn
								icon
								tag="a"
								:href="getFileUrl(item)"
								download
								@click.stop
							>
								<v-icon color="black">
									mdi-download
								</v-icon>
							</v-btn>
						</v-list-item-action>
						<v-list-item-action v-if="!item.isParent && item.url">
							<v-btn
								icon
								tag="a"
								target='_blank'
								:href="item.url"
								@click.stop
							>
								<v-icon color="black">
									mdi-eye
								</v-icon>
							</v-btn>
						</v-list-item-action>
						<v-list-item-action v-if="isSearch">
							<v-btn
								icon
								tag="a"
								:href="getFileUrl(item, true)"
								@click.stop
							>
								<v-icon color="black">
									mdi-folder
								</v-icon>
							</v-btn>
						</v-list-item-action>
					</v-list-item>
				</v-card>
			</v-col>
		</v-row>
	</v-container>
</template>
<script>
import { format } from 'date-fns'
import prettyBytes from 'pretty-bytes'
import nodeUrl from 'url'
import nodePath from 'path'
import api from '../api'
import FileUploadDialog from './FileUploadDialog'

const FOLDER_MIME_TYPE = "application/vnd.google-apps.folder";

const ICON_NAME = {
	'application/vnd.google-apps.folder': 'mdi-folder',
	'application/epub+zip': 'mdi-book',
	'application/vnd.android.package-archive': 'mdi-android',
	'video/mp4': 'mdi-video',
	'video/x-msvideo': 'mdi-video',
	'video/x-flv': 'mdi-video',
	'video/x-ms-wmv': 'mdi-video',
	'video/webm': 'mdi-video',
	'video/x-matroska': 'mdi-video',
	'application/zip': 'mdi-archive',
	'application/x-7z-compressed': 'mdi-archive',
	'application/x-rar-compressed': 'mdi-archive',
	'application/x-gzip': 'mdi-archive',
	'image/png': 'mdi-file-image',
	'image/jpeg': 'mdi-file-image',
	'image/gif': 'mdi-file-image',
	'image/bmp': 'mdi-file-image',
	'application/msword': 'mdi-file-word',
	'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
		'mdi-file-word',
	'application/vnd.ms-excel': 'mdi-file-excel',
	'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
		'mdi-file-excel',
	'application/vnd.openxmlformats-officedocument.presentationml.presentation':
		'mdi-file-powerpoint',
	'application/vnd.ms-powerpoint': 'mdi-file-powerpoint',
	'application/pdf': 'mdi-file-pdf',
	'text/x-sql': 'mdi-database',
	'application/vnd.google-apps.document': 'mdi-file-document-box',
	'application/vnd.google-apps.spreadsheet': 'mdi-google-spreadsheet',
	'application/vnd.google-apps.presentation': 'mdi-file-presentation-box',
	'text/plain': 'mdi-file-document'
}
export default {
	data() {
		return {
			list: [],
			loading: false,
			headers: [
				{
					text: this.$t('fileName'),
					value: 'fileName',
					class: ['fileName']
				},
				{
					text: this.$t('modifiedTime'),
					value: 'modifiedTime',
					filterable: false,
					class: 'hidden-sm-and-down'
				},
				{
					text: this.$t('fileSize'),
					value: 'fileSize',
					filterable: false,
					class: 'hidden-sm-and-down'
				}
			],
			renderStart: null,
			uploadEnabled: window.props.upload,
			showUploadDialog: false
		}
	},
	computed: {
		uploadUrl() {
			const u = new URL("/", window.props.api)
			u.searchParams.set(
				'rootId',
				this.$route.query.rootId || window.props.default_root_id
			)
			return u.href
		},
		isSearch() {
			return !!this.$route.query.q;
		},
		title() {
			return this.isSearch ? `Search Results for '${this.$route.query.q}'` : this.$route.query.id
		}
	},
	methods: {
		getFileUrl(item, parent=null) {
			if (parent == null) parent = item.isParent;
			var url = new URL("/", window.props.api);
			
			if (item.mimeType != FOLDER_MIME_TYPE) {
				url.searchParams.set("view",1);
			}
			if (this.$route.query.rootId) {
				url.searchParams.set("rootId", this.$route.query.rootId)
			}
			url.searchParams.set("id", parent ? item.parents[0] : item.id)
			return url.href;
		},
		/* getFileViewUrl(item) {
			if (item.isFolder) {
				return `https://drive.google.com/drive/folders/${item.id}`;
			} else {
				return `https://drive.google.com/file/d/${item.id}/view?usp=sharing`;
			}
		}, */
		async load() {

			var query = this.$route.query;

			let renderStart = (this.renderStart = Date.now()) // Withous this, when user regret navigating a big folder, it will have some conflict.
			this.loading = true

			this.list = [];
			var qs = {
				rootId: query.rootId || window.props.default_root_id,
			}
			if (query.q) qs.q = query.q;
			if (query.id) qs.id = query.id;
			const { files } = await api
				.post("/", {
					method: 'POST',
					qs
				})
				.json()
			if (renderStart !== this.renderStart) {
				// User had initiated other folder navigation request
				return
			}

			this.list = files
			.filter(f => !f.description || !f.description.includes("[[hidden]]"))
			.filter(f=> !f.isParent || f.parents)
			.map(f => {
				f.mimeType = f.mimeType.replace('; charset=utf-8', '')
				const isFolder =
					f.mimeType === 'application/vnd.google-apps.folder'
				const isGoogleFile = f.mimeType.includes('vnd.google-apps')
				const o = {
					id: f.id,
					parents: f.parents,
					isParent: !!f.isParent,
					fileName: f.name,
					modifiedTime: format(
						new Date(f.modifiedTime),
						'yyyy/MM/dd HH:mm:ss'
					),
					isFolder,
					isGoogleFile,
					mimeType: f.mimeType,
					fileSize: f.size ? prettyBytes(parseInt(f.size)) : '',
					url: f.webViewLink || f.webContentLink,
					icon: ICON_NAME[f.mimeType] || 'mdi-file'
				}
				return o
			})
			this.loading = false
		},
		uploadComplete() {
			this.showUploadDialog = false
			this.load()
		}
	},
	created() {
		this.load()
	},
	beforeRouteUpdate(to, from, next) {
		/* const fullyEncoded = to.params.path
			.split('/')
			.map(decodeURIComponent)
			.map(encodeURIComponent)
			.join('/') // because vue-router's encoding is a little bit weird... */
		next()
		this.load();
	},
	components: {
		FileUploadDialog
	}
}
</script>
<style scoped>
.fake-tr {
	display: table-row;
	vertical-align: inherit;
	border-color: inherit;
	color: inherit;
	text-decoration: none;
}
.theme--light.v-data-table
	tbody
	.fake-tr:hover:not(.v-data-table__expanded__content) {
	background: #eeeeee;
}
.theme--light.v-data-table
	tbody
	.fake-tr:not(:last-child)
	td:not(.v-data-table__mobile-row) {
	border-bottom: 1px solid rgba(0, 0, 0, 0.12);
}
.line-height {
	height: 48px;
	line-height: 48px;
}
.wrapper {
	display: flex;
	align-items: center;
}
.icon-wrapper {
	box-sizing: border-box;
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
}
</style>
